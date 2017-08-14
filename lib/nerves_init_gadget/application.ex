defmodule Nerves.InitGadget.Application do
  @moduledoc false

  @interface "usb0"

  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    # Define workers and child supervisors to be supervised
    children = [
      worker(Nerves.InitGadget.NetworkManager, [@interface])
    ]

    # Start link-local networking going on the USB interface
    Nerves.Network.setup @interface, ipv4_address_method: :linklocal
    Mdns.Server.add_service(%Mdns.Server.Service{
      domain: "nerves.local",
      data: :ip,
      ttl: 120,
      type: :a
    })

    opts = [strategy: :one_for_one, name: Nerves.InitGadget.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
