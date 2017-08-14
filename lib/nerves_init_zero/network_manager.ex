defmodule Nerves.InitGadget.NetworkManager do
  use GenServer

  require Logger

  # @app Mix.Project.config[:app]
  @scope [:state, :network_interface]

  def start_link(iface) do
    GenServer.start_link(__MODULE__, iface)
  end

  def init(iface) do
    Logger.debug("Start Network Manager")
    SystemRegistry.register()
    {:ok, {iface, nil}}
  end

  def handle_info({:system_registry, :global, registry}, {iface, current}) do
    scope = scope(iface, [:ipv4_address])
    ip = get_in(registry, scope)
    if ip != current do
      Logger.debug("IP Address Changed")
      configure_mdns(ip)
    end
    {:noreply, {iface, ip}}
  end

  defp configure_mdns(ip) do
    Logger.debug("Reconfiguring mDNS IP: #{inspect ip}")
    ip =
      String.split(ip, ".")
      |> Enum.map(&parse_int/1)
      |> List.to_tuple

    Mdns.Server.stop()
    Mdns.Server.start(interface: ip)
    Mdns.Server.set_ip(ip)
  end

  defp scope(iface, append) do
    @scope ++ [iface] ++ append
  end

  defp parse_int(str) do
    {int, _} = Integer.parse(str)
    int
  end
end
