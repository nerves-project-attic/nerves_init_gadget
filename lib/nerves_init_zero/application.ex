defmodule Nerves.InitZero.Application do
  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false
  @interface "usb0"

  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    # Define workers and child supervisors to be supervised
    children = [
      # Starts a worker by calling: NervesInitZero.Worker.start_link(arg1, arg2, arg3)
      # worker(NervesInitZero.Worker, [arg1, arg2, arg3]),
      worker(Nerves.InitZero.NetworkManager, [@interface])
    ]

    # Start link-local networking going on the USB interface
    Nerves.Network.setup @interface, ipv4_address_method: :linklocal
    
    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Nerves.InitZero.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
