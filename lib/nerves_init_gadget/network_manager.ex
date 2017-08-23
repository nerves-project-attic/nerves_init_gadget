defmodule Nerves.InitGadget.NetworkManager do
  use GenServer

  require Logger

  @moduledoc false

  @scope [:state, :network_interface]

  defmodule State do
    @moduledoc false
    defstruct ifname: nil, ip: nil
  end

  def start_link(ifname) do
    GenServer.start_link(__MODULE__, ifname)
  end

  def init(ifname) do
    SystemRegistry.register()
    {:ok, %State{ifname: ifname}}
  end

  def handle_info({:system_registry, :global, registry}, state) do
    scope = scope(state.ifname, [:ipv4_address])
    ip = get_in(registry, scope)
    if ip != state.ip do
      Logger.debug("IP address for #{state.ifname} changed to #{inspect ip}")
      update_mdns(ip)
    end
    {:noreply, %{state | ip: ip}}
  end

  defp update_mdns(ip_str) do
    ip = to_ip_tuple(ip_str)
    Mdns.Server.stop()
    Mdns.Server.start(interface: ip)
    Mdns.Server.set_ip(ip)
  end

  defp scope(ifname, append) do
    @scope ++ [ifname] ++ append
  end

  defp to_ip_tuple(str) do
    str
    |> String.split(".")
    |> Enum.map(&String.to_integer/1)
    |> List.to_tuple
  end
end
