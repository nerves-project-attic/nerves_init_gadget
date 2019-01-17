defmodule Nerves.InitGadget.NetworkManager do
  @moduledoc false

  use GenServer
  require Logger

  defmodule State do
    @moduledoc false
    defstruct ip: nil, is_up: nil, opts: nil
  end

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  def init(opts) do
    # Register for updates from system registry
    SystemRegistry.register()

    state =
      %State{opts: opts}
      |> force_network_setup(opts)
      |> init_mdns(opts)
      |> init_net_kernel(opts)

    {:ok, state}
  end

  def handle_info({:system_registry, :global, registry}, state) do
    {changed, new_state} = update_state(state, registry)

    case changed do
      :up -> handle_if_up(new_state)
      :down -> handle_if_down(new_state)
      _ -> :ok
    end

    {:noreply, new_state}
  end

  defp update_state(%{opts: %{address_method: :dhcpd}} = state, registry) do
    # Trigger off `:is_lower_up`. The "lower" comes up after a delay on some
    # interfaces. If things are configured before the "lower" is up then
    # packets down get received. This results in weird behavior like the DHCP
    # server not receiving anything until a packet gets sent.
    new_is_up = get_in(registry, [:state, :network_interface, state.opts.ifname, :is_lower_up])

    case {new_is_up == state.is_up, new_is_up} do
      {true, _} -> {:unchanged, state}
      {false, true} -> {:up, %{state | is_up: true}}
      {false, _is_up} -> {:down, %{state | is_up: new_is_up}}
    end
  end

  defp update_state(state, registry) do
    new_ip = get_in(registry, [:state, :network_interface, state.opts.ifname, :ipv4_address])

    case {new_ip == state.ip, new_ip} do
      {true, _} -> {:unchanged, state}
      {false, nil} -> {:down, %{state | ip: nil, is_up: false}}
      {false, _ip} -> {:up, %{state | ip: new_ip, is_up: true}}
    end
  end

  defp force_network_setup(state, %{address_method: :dhcpd} = opts) do
    # Use the IP address calculated by OneDHCPD with Nerves.Network.
    subnet = OneDHCPD.IPCalculator.default_subnet(opts.ifname)

    our_ip =
      OneDHCPD.IPCalculator.our_ip_address(subnet)
      |> :inet.ntoa()
      |> to_string()

    subnet_mask =
      OneDHCPD.IPCalculator.mask()
      |> :inet.ntoa()
      |> to_string()

    network_opts =
      :nerves_network
      |> Application.get_env(:default, [])
      |> Keyword.get(to_atom(opts.ifname), [])
      |> Keyword.put(:ipv4_address_method, :static)
      |> Keyword.put(:ipv4_address, our_ip)
      |> Keyword.put(:ipv4_subnet_mask, subnet_mask)

    Nerves.Network.setup(opts.ifname, network_opts)

    # Update Erlang's DNS resolver so that the IP addresses given out
    # can be referred to by name.
    :inet_db.add_host(OneDHCPD.IPCalculator.our_ip_address(subnet), ['local.#{opts.ifname}.lan'])
    :inet_db.add_host(OneDHCPD.IPCalculator.their_ip_address(subnet), ['peer.#{opts.ifname}.lan'])

    %{state | ip: our_ip}
  end

  defp force_network_setup(state, opts) do
    network_opts =
      :nerves_network
      |> Application.get_env(:default, [])
      |> Keyword.get(to_atom(opts.ifname), [])
      |> Keyword.put_new(:ipv4_address_method, opts.address_method)

    Nerves.Network.setup(opts.ifname, network_opts)
    state
  end

  # Workaround for static IP
  defp handle_if_up(%{opts: %{address_method: :dhcpd}} = state) do
    Logger.debug("#{state.opts.ifname} is up. IP is #{state.ip}")

    OneDHCPD.start_server(state.opts.ifname)
    update_mdns(state.ip, state.opts.mdns_domain)
    update_net_kernel(state.ip, state.opts)
  end

  defp handle_if_up(state) do
    Logger.debug("#{state.opts.ifname} is up. IP is now #{state.ip}")

    update_mdns(state.ip, state.opts.mdns_domain)
    update_net_kernel(state.ip, state.opts)
  end

  defp handle_if_down(%{address_method: :dhcpd} = state) do
    Logger.debug("#{state.opts.ifname} is down.")
    OneDHCPD.stop_server(state.opts.ifname)
  end

  defp handle_if_down(_state), do: :ok

  defp init_mdns(state, %{mdns_domain: nil}), do: state

  defp init_mdns(state, opts) do
    Mdns.Server.add_service(%Mdns.Server.Service{
      domain: resolve_mdns_name(opts.mdns_domain),
      data: :ip,
      ttl: 120,
      type: :a
    })

    state
  end

  defp resolve_mdns_name(nil), do: nil

  defp resolve_mdns_name(:hostname) do
    {:ok, hostname} = :inet.gethostname()

    to_dot_local_name(hostname)
  end

  defp resolve_mdns_name(mdns_name), do: mdns_name

  defp to_atom(value) when is_atom(value), do: value
  defp to_atom(value) when is_binary(value), do: String.to_atom(value)

  defp to_dot_local_name(name) do
    # Use the first part of the domain name and concatenate '.local'
    name
    |> to_string()
    |> String.split(".")
    |> hd()
    |> Kernel.<>(".local")
  end

  defp update_mdns(_ip, nil), do: :ok

  defp update_mdns(ip, _mdns_domain) do
    ip_tuple = string_to_ip(ip)
    Mdns.Server.stop()

    # Give the interface time to settle to fix an issue where mDNS's multicast
    # membership is not registered. This occurs on wireless interfaces and
    # needs to be revisited.
    :timer.sleep(100)

    Mdns.Server.start(interface: ip_tuple)
    Mdns.Server.set_ip(ip_tuple)
  end

  defp init_net_kernel(state, opts) do
    if erlang_distribution_enabled?(opts) do
      :os.cmd('epmd -daemon')
    end

    state
  end

  defp update_net_kernel(ip, opts) do
    new_name = make_node_name(opts, ip)

    if new_name do
      :net_kernel.stop()

      case :net_kernel.start([new_name]) do
        {:ok, _} ->
          Logger.debug("Restarted Erlang distribution as node #{inspect(new_name)}")

        {:error, reason} ->
          Logger.error("Erlang distribution failed to start: #{inspect(reason)}")
      end
    end
  end

  defp string_to_ip(s) do
    {:ok, ip} = :inet.parse_address(to_charlist(s))
    ip
  end

  defp erlang_distribution_enabled?(opts) do
    make_node_name(opts, "fake.ip") != nil
  end

  defp resolve_dhcp_name(fallback) do
    with {:ok, hostname} <- :inet.gethostname(),
         {:ok, {:hostent, dhcp_name, _, _, _, _}} <- :inet.gethostbyname(hostname) do
      dhcp_name
    else
      _ -> fallback
    end
  end

  defp make_node_name(%{node_name: name, node_host: :ip}, ip) do
    to_node_name(name, ip)
  end

  defp make_node_name(%{node_name: name, node_host: :dhcp}, ip) do
    to_node_name(name, resolve_dhcp_name(ip))
  end

  defp make_node_name(%{node_name: name, node_host: :mdns_domain, mdns_domain: host}, _ip)
       when host != nil do
    to_node_name(name, resolve_mdns_name(host))
  end

  defp make_node_name(%{node_name: name, node_host: :mdns_domain, mdns_domain: host}, ip)
       when host == nil do
    # revert to IP address if no mdns domain
    to_node_name(name, ip)
  end

  defp make_node_name(%{node_name: name, node_host: host}, _ip) do
    to_node_name(name, host)
  end

  defp to_node_name(nil, _host), do: nil
  defp to_node_name(_name, nil), do: nil
  defp to_node_name(name, host), do: :"#{name}@#{host}"
end
