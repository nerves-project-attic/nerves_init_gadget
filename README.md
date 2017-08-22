# nerves_init_gadget
[![Hex version](https://img.shields.io/hexpm/v/nerves_init_gadget.svg "Hex version")](https://hex.pm/packages/nerves_init_gadget)

This project adds a basic level of setup for Nerves devices with USB gadget mode
interfaces like the Raspberry Pi Zero. Here are some features:

* Automatically sets up link-local networking on the USB interface. No DHCP or
  static IP setup is needed on the host laptop
* Sets up mDNS to respond to lookups for `nerves.local`
* Pulls in the `nerves_runtime` initialization for things like mounting and
  fixing the application filesystem
* Starts `nerves_firmware_ssh` so that firmware push updates work
* If used with [bootloader](https://github.com/nerves-project/bootloader),
  crashes in your application's initialization won't break firmware updates

While you'll probably want to create your own device initialization project at
some point, this project serves as a great starting point, especially if you're
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

Now, add the following configuration to your `config/config.exs` (replace
`:your_app)`:

```elixir
# Boot the bootloader first and have it start our app.
config :bootloader,
  init: [:nerves_init_gadget],
  app: :your_app
```

The final configuration item is to set up authorized keys for pushing
firmware updates to the device. This is documented in more detail at
[nerves_firmware_ssh](https://github.com/fhunleth/nerves_firmware_ssh).
Basically, the device will need to know the `ssh` public keys for all of the
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

If you're using Ubuntu and `ping` doesn't work, check the Network Settings for
the `usb0` interface and set the IPv4 Method to "Link-Local Only".

To update firmware from now on, just run the following:

```
$ MIX_TARGET=rpi0 mix firmware.push nerves.local
```

Change `MIX_TARGET` to whatever you're using to build the firmware.  Assuming
everything completes successfully, the device will reboot with the new firmware.

If you have a password-protected `ssh` private key, `mix firmware.push` currently
isn't able to prompt for the password or use the `ssh-agent`. This means that you
either need to pass your password in cleartext on the commandline (ugh), create
a new public/private key pair, or use commandline `ssh`. For commandline `ssh`,
take a look at the `upload.sh` script from
[nerves_firmware_ssh](https://github.com/fhunleth/nerves_firmware_ssh) for an
example.

## Troubleshooting

If things aren't working, try the following to figure out what's wrong:

1. Check that you're plugged into the right USB port on the target. The
   Raspberry Pi Zero, for example, has two USB ports but one of them is only for
   power.
2. Check that the USB cable works (some cables are power-only and don't have the
   data lines hooked up). Try connecting to the virtual serial port using
   `picocom` or `screen` to get to the IEx prompt.
3. Check your host machine's Ethernet settings. You'll want to make sure that
   link-local addressing is enabled on the virtual Ethernet interface. Static
   addresses won't work. DHCP addressing should eventually work since link-local
   addressing is what happens when DHCP fails. The IP address that's assigned to
   the virtual Ethernet interface should be in the 169.254.0.0/16 subnet.
4. Reboot the target and connect over the virtual serial port as soon as it
   allows. Watch the log messages to see that an IP address is assigned to the
   virtual Ethernet port. Try pinging that directly. If nothing is assigned,
   it's possible that something is wrong with the Ethernet gadget device drivers
   but that's more advanced to debug and shouldn't be an issue if you haven't
   modified the official Nerves systems.
5. If you're having trouble with firmware updates, check out the
   [`nerves_firmware_ssh` troubleshooting steps](https://github.com/fhunleth/nerves_firmware_ssh#troubleshooting).
6. If all else fails, please file an [issue](https://github.com/fhunleth/nerves_init_gadget/issues/new)
   or try the `#nerves` channel on the [Elixir Slack](https://elixir-slackin.herokuapp.com/).
   Inevitably someone else will hit your problem too and we'd like to improve
   the experience for future users.
