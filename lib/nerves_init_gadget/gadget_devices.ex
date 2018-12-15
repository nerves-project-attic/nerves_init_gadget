defmodule Nerves.InitGadget.GadgetDevices do
  @moduledoc """
  Set up the gadget devices with usb_gadget
  """
  use GenServer, restart: :temporary

  require Logger

  @doc false
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(_opts) do
    # Only set up gadget devices if USB gadget configfs is available so that
    # nerves_init_gadget works on targets that don't have USB OTG ports or
    # for older systems that have the gadget devices compiled into the kernel.
    case USBGadget.Builtin.create_rndis_ecm_acm("g") do
      :ok ->
        # Make sure we clear out any existing gadget configuration.
        :os.cmd('rmmod g_cdc')
        USBGadget.disable_device("g")

        USBGadget.enable_device("g")
        setup_bond0()
        {:ok, :ok}

      error ->
        Logger.warn("Error setting up USB gadgets: #{inspect(error)}")
        {:ok, error}
    end
  end

  def handle_call(:status, _from, state) do
    {:reply, state, state}
  end

  def status do
    GenServer.call(__MODULE__, :status)
  end

  defp setup_bond0 do
    # Set up the bond0 interface across usb0 and usb1.
    # In the rndis_ecm_acm pre-defined device being used here, usb0 is the
    # RNDIS (Windows-compatible) device and usb1 is the ECM
    # (non-Windows-compatible) device.
    # Since Linux supports both with ECM being more reliable, we set usb1 (ECM)
    # as the primary, meaning that it will be used if both are available.
    :os.cmd('ip link set bond0 down')
    File.write("/sys/class/net/bond0/bonding/mode", "active-backup")
    File.write("/sys/class/net/bond0/bonding/miimon", "100")
    File.write("/sys/class/net/bond0/bonding/slaves", "+usb0")
    File.write("/sys/class/net/bond0/bonding/slaves", "+usb1")
    File.write("/sys/class/net/bond0/bonding/primary", "usb1")
    :os.cmd('ip link set bond0 up')
  end
end
