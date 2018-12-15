defmodule Nerves.InitGadget do
  @moduledoc """
  `nerves_init_gadget` adds a basic level of setup for Nerves devices with USB
  gadget mode interfaces like the Raspberry Pi Zero. Here are some features:

  * Initialize USB gadget devices using configfs
  * Automatically sets up link-local networking on the USB interface. No DHCP or
    static IP setup is needed on the host laptop
  * Sets up mDNS to respond to lookups for `nerves.local`
  * Pulls in the `nerves_runtime` initialization for things like mounting and
    fixing the application filesystem
  * Starts `nerves_firmware_ssh` so that firmware push updates work
  * If used with [shoehorn](https://github.com/nerves-project/shoehorn),
    crashes in your application's initialization won't break firmware updates

  While you'll probably want to create your own device initialization project at
  some point, this project serves as a great starting point, especially if you're
  new to Nerves.

  All configuration is handled at compile-time, so there's not an API. See the
  `README.md` for installation and use instructions.
  """
end
