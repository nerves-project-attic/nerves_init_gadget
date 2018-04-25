defmodule Nerves.InitGadget.SSHConsole do
  @moduledoc """
  SSH IEx console.
  """
  use GenServer

  @doc false
  def start_link(%{ssh_console_port: nil}), do: :ignore

  def start_link(opts) do
    GenServer.start_link(__MODULE__, [opts], name: __MODULE__)
  end

  def init([opts]) do
    ssh = start_ssh(opts)
    {:ok, %{ssh: ssh, opts: opts}}
  end

  def terminate(_, %{ssh: ssh}) do
    :ssh.stop_daemon(ssh)
  end

  defp start_ssh(%{ssh_console_port: port}) do
    # Reuse keys from `nerves_firmware_ssh` so that the user only needs one
    # config.exs entry.
    authorized_keys =
      Application.get_env(:nerves_firmware_ssh, :authorized_keys, [])
      |> Enum.join("\n")

    decoded_authorized_keys = :public_key.ssh_decode(authorized_keys, :auth_keys)

    cb_opts = [authorized_keys: decoded_authorized_keys]

    # Reuse the system_dir as well to allow for auth to work with the shared
    # keys.
    {:ok, ssh} =
      :ssh.daemon(port, [
        {:id_string, :random},
        {:key_cb, {Nerves.Firmware.SSH.Keys, cb_opts}},
        {:system_dir, Nerves.Firmware.SSH.Application.system_dir()},
        {:shell, {Elixir.IEx, :start, []}}
      ])

    ssh
  end
end
