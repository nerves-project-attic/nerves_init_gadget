defmodule Nerves.InitGadget.Application do
  @moduledoc false

  use Application
  alias Nerves.InitGadget

  def start(_type, _args) do
    opts = InitGadget.Options.get()

    children = [
      {InitGadget.GadgetDevices, opts},
      {InitGadget.NetworkManager, opts},
      {InitGadget.SSHConsole, opts}
    ]

    opts = [strategy: :one_for_one, name: InitGadget.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
