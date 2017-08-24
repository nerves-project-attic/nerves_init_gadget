defmodule Nerves.InitGadget.NetworkManager do
  use GenServer

  require Logger

  @moduledoc false

  defmodule State do
    @moduledoc false
    defstruct ifname: nil,
              ip: nil,
              opts: nil
  end

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  def init(opts) do
    # Register for updates from system registry
    SystemRegistry.register()

    # Initialize networking
    Nerves.Network.setup(opts.ifname, ipv4_address_method: opts.address_method)
    init_mdns(opts.mdns_domain)
    init_net_kernel(opts.node_name)

    {:ok, %State{ifname: opts.ifname, opts: opts}}
  end

  def handle_info({:system_registry, :global, registry}, state) do
    new_ip = get_in(registry, [:state, :network_interface, state.ifname, :ipv4_address])
    handle_ip_update(state, new_ip)
  end

  defp handle_ip_update(%{ip: old_ip} = state, new_ip) when old_ip == new_ip do
    # No change
    {:noreply, state}
  end
  defp handle_ip_update(state, new_ip) do
    Logger.debug("IP address for #{state.ifname} changed to #{new_ip}")
    update_mdns(new_ip, state.opts.mdns_domain)
    update_net_kernel(new_ip, state.opts.node_name)
    {:noreply, %{state | ip: new_ip}}
  end

  defp init_mdns(nil), do: :ok
  defp init_mdns(mdns_domain) do
    Mdns.Server.add_service(%Mdns.Server.Service{
      domain: mdns_domain,
      data: :ip,
      ttl: 120,
      type: :a
    })
  end

  defp update_mdns(_ip, nil), do: :ok
  defp update_mdns(ip, _mdns_domain) do
    ip_tuple = to_ip_tuple(ip)
    Mdns.Server.stop()
    Mdns.Server.start(interface: ip_tuple)
    Mdns.Server.set_ip(ip_tuple)
  end

  defp init_net_kernel(nil), do: :ok
  defp init_net_kernel(_name) do
    :os.cmd('epmd -daemon')
  end

  defp update_net_kernel(_ip, nil), do: :ok
  defp update_net_kernel(ip, name) do
    :net_kernel.stop()
    :net_kernel.start([:"#{name}@#{ip}"])
  end

  defp to_ip_tuple(str) do
    str
    |> String.split(".")
    |> Enum.map(&String.to_integer/1)
    |> List.to_tuple
  end
end
