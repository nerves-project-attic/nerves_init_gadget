defmodule Nerves.InitGadget.NetworkManager do
  @moduledoc false

  use GenServer
  require Logger

  defmodule State do
    @moduledoc false
    defstruct ip: nil, opts: nil
  end

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  def init(opts) do
    # Register for updates from system registry
    SystemRegistry.register()

    # Initialize networking
    network_opts =
      :nerves_network
      |> Application.get_env(:default, [])
      |> Keyword.get(to_atom(opts.ifname), [])
      |> Keyword.put(:ipv4_address_method, opts.address_method)

    Nerves.Network.setup(opts.ifname, network_opts)
    init_mdns(opts.mdns_domain)
    init_net_kernel(opts)

    {:ok, %State{opts: opts}}
  end

  def handle_info({:system_registry, :global, registry}, state) do
    new_ip = get_in(registry, [:state, :network_interface, state.opts.ifname, :ipv4_address])
    handle_ip_update(state, new_ip)
  end

  # New IP address is same as current IP address
  defp handle_ip_update(%{ip: ip} = state, ip), do: {:noreply, state}

  defp handle_ip_update(state, new_ip) do
    Logger.debug("IP address for #{state.opts.ifname} changed to #{new_ip}")
    update_mdns(new_ip, state.opts.mdns_domain)
    update_net_kernel(new_ip, state.opts)
    {:noreply, %State{state | ip: new_ip}}
  end

  defp init_mdns(nil), do: :ok

  defp init_mdns(mdns_domain) do
    Mdns.Server.add_service(%Mdns.Server.Service{
      domain: resolve_mdns_name(mdns_domain),
      data: :ip,
      ttl: 120,
      type: :a
    })
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
    ip_tuple = to_ip_tuple(ip)
    Mdns.Server.stop()

    # Give the interface time to settle to fix an issue where mDNS's multicast
    # membership is not registered. This occurs on wireless interfaces and
    # needs to be revisited.
    :timer.sleep(100)

    Mdns.Server.start(interface: ip_tuple)
    Mdns.Server.set_ip(ip_tuple)
  end

  defp init_net_kernel(opts) do
    if erlang_distribution_enabled?(opts) do
      :os.cmd('epmd -daemon')
    end
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

  defp to_ip_tuple(str) do
    str
    |> String.split(".")
    |> Enum.map(&String.to_integer/1)
    |> List.to_tuple()
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
