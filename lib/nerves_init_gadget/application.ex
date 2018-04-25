defmodule Nerves.InitGadget.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    config_opts = Map.new(Application.get_all_env(:nerves_init_gadget))
    merged_opts = Map.merge(%Nerves.InitGadget.Options{}, config_opts)

    # Define workers and child supervisors to be supervised
    children = [
      worker(Nerves.InitGadget.NetworkManager, [merged_opts]),
      worker(Nerves.InitGadget.SSHConsole, [merged_opts])
    ]

    opts = [strategy: :one_for_one, name: Nerves.InitGadget.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
