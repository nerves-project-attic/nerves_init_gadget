defmodule Nerves.InitZero.NetworkManager do
  use GenServer

  require Logger

  # @app Mix.Project.config[:app]
  @scope [:state, :network_interface]

  def start_link(iface) do
    GenServer.start_link(__MODULE__, iface)
  end

  def init(iface) do
    Logger.debug "Start Network Manager"
    :os.cmd 'epmd -daemon'
    SystemRegistry.register
    {:ok, {iface, nil}}
  end

  def handle_info({:system_registry, :global, registry}, {iface, current}) do
    scope = scope(iface, [:ipv4_address])
    ip = get_in(registry, scope)
    if ip != current do
      Logger.debug "IP Address Changed"
      #restart_net_kernel(ip)
      configure_mdns(ip)
    end
    {:noreply, {iface, ip}}
  end

  # defp restart_net_kernel(ip) do
  #   Logger.debug "Restarting Net Kernel"
  #   :net_kernel.stop()
  #   :net_kernel.start([:"#{@app}@#{ip}"])
  # end

  defp configure_mdns(ip) do
    Logger.debug "Reconfiguring MDNS IP: #{inspect ip}"
    # :timer.sleep(2000)
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
