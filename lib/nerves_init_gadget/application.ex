defmodule Nerves.InitGadget.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    config_opts = Map.new(Application.get_all_env(:nerves_init_gadget))
    merged_opts = Map.merge(%Nerves.InitGadget.Options{}, config_opts)

    children = [
      {Nerves.InitGadget.NetworkManager, merged_opts},
      {Nerves.InitGadget.SSHConsole, merged_opts}
    ]

    opts = [strategy: :one_for_one, name: Nerves.InitGadget.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
