# nerves_init_gadget
[![Hex version](https://img.shields.io/hexpm/v/nerves_init_gadget.svg "Hex version")](https://hex.pm/packages/nerves_init_gadget)

This project adds a basic level of setup for Nerves devices with USB gadget mode
interfaces like the Raspberry Pi Zero. Here are some features:

* Automatically sets up link local networking on the USB interface. No DHCP or
  static IP setup needed on the host laptop
* Sets up mDNS to respond to lookups for `nerves.local`
* Pulls in the `nerves_runtime` initialization for things like mounting and
  fixing the application filesystem
* Starts `nerves_firmware_ssh` so that push firmware updates work
* If used with [bootloader](https://github.com/nerves-project/bootloader),
  crashes in your application's initialization won't break firmware updates

While you'll probably want to create your own device initialization project at
some point, this project serves as a great starting point especially if you're
new to Nerves.

## Installation

This project works best with
[bootloader](https://github.com/nerves-project/bootloader), so add both it and
`bootloader` to your dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:bootloader, "~> 0.1"},
    {:nerves_init_gadget, "~> 0.1"}
  ]
end
```

Bootloader requires a plugin to the
[distillery](https://github.com/bitwalker/distillery) configuration, so add it
to your `rel/config.exs` (replace `:your_app`):

```elixir
release :your_app do
  plugin Bootloader.Plugin
  ...
end
```

Now add the following configuration to your `config/config.exs` (replace
`:your_app)`:

```elixir
# Boot the bootloader first and have it start our app.
config :bootloader,
  init: [:nerves_init_gadget],
  app: :your_app
```

The final configuration is item is to set up authorized keys for pushing
firmware updates to the device. This is documented in more detail at
[nerves_firmware_ssh](https://github.com/fhunleth/nerves_firmware_ssh).
Basically the device will need to know the `ssh` public keys for all of the
users that are allowed to update the firmware. Copy the contents of the
`id_rsa.pub`, etc.  files from your `~/.ssh` directory here like this:

```
config :nerves_firmware_ssh,
  authorized_keys: [
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAAAgQDBCdMwNo0xOE86il0DB2Tq4RCv07XvnV7W1uQBlOOE0ZZVjxmTIOiu8XcSLy0mHj11qX5pQH3Th6Jmyqdj",
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCaf37TM8GfNKcoDjoewa6021zln4GvmOiXqW6SRpF61uNWZXurPte1u8frrJX1P/hGxCL7YN3cV6eZqRiF"
  ]
```

That's it! Run `mix deps.get` and `mix firmware` like usual and copy the new
image to your device.

## Using

Give your device a few seconds to boot and initialize the virtual Ethernet
interface going through the USB cable. On your computer, run `ping` to see that
it's working:

```
$ ping nerves.local
```

To update firmware from now on, just run the following:

```
$ MIX_TARGET=rpi0 mix firmware.push nerves.local
```

Change `MIX_TARGET` to whatever you're using to build the firmware.  Assuming
everything completes successfully, the device will reboot with the new firmware.

If you have a password-protected ssh private key, `mix firmware.push` currently
isn't able to prompt for the password like commandline `ssh`. See
[nerves_firmware_ssh](https://github.com/fhunleth/nerves_firmware_ssh) for the
`upload.sh` script which uses commandline `ssh` and doesn't have this issue.

