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
* Configure Erlang Distribution so that you can remsh into a device, use
  Observer or other debug and tracing tools

While you'll probably want to create your own device initialization project at
some point, this project serves as a great starting point, especially if you're
new to Nerves.

## Installation for a new project

If you already have a project that uses Nerves, then see the next section.

First, it's always useful to refer back to the [Nerves Project Getting Started
instructions](https://hexdocs.pm/nerves/getting-started.html). These
instructions skip platform-specific installation steps and assume that you've
used Nerves at least once before.

Make sure that your Nerves archive is up-to-date. The Nerves archive contains
the new project generator:

```sh
mix local.nerves

# or if you don't have it yet
mix archive.install https://github.com/nerves-project/archives/raw/master/nerves_bootstrap.ex
```

Create a new project using the generator:
```sh
mix nerves.new mygadget
```

Add `nerves_init_gadget` to the deps in the `mix.exs`:
```elixir
def deps(target) do
  [ system(target),
    {:bootloader, "~> 0.1"},
    {:nerves_runtime, "~> 0.4"},
    {:nerves_init_gadget, "~> 0.1"}
  ]
end
```

Now add `nerves_init_gadget` to the list of applications to always start. If you
haven't used `bootloader` before, it separates the application initialization
into phases to isolate failures. This lets us ensure that `nerves_init_gadget`
runs even if we messed up something in our application code. It's useful during
development so that you can still send firmware updates to a device.

```elixir
# Boot the bootloader first and have it start our app.
config :bootloader,
  init: [:nerves_init_gadget],
  app: :mygadget
```

Next, set up the ssh authorized keys for pushing firmware updates to the device.
This is documented in more detail at
[nerves_firmware_ssh](https://github.com/fhunleth/nerves_firmware_ssh). The
following fragment inserts your `id_rsa.pub` at compile time, but you can also
copy/paste the keys.

```elixir
config :nerves_firmware_ssh,
  authorized_keys: [
    File.read!(Path.join(System.user_home!, ".ssh/id_rsa.pub"))
  ]
```

Finally, run the usual Elixir and Nerves build steps:

```sh
# Modify for your board
export MIX_TARGET=rpi0

mix deps.get
mix firmware` like usual and copy the new
image to your device in the normal way. For devices that use MicroSD cards, run
`mix firmware.burn`.
```

Since debugging ssh is particularly painful, take this opportunity to double
check the authorized key one last time.

```sh
find . -name sys.config

# This should print out the configuration that was compiled into the image. If
# you have multiple ones since you've been compiling for more than one device,
# pick the one that makes sense. The following is the one that I had:

cat ./_build/rpi0/dev/rel/mygadget/releases/0.1.0/sys.config
```

Now you should be able to boot the device and push firmware updates to it. See
the sections below for doing this and troubleshooting.

## Installation for an existing project

These instructions assume that your existing project is configured to expose a
virtual Ethernet adapter and virtual serial port on the target. The official
`nerves_system_rpi0` does this.

This project works well with
[bootloader](https://github.com/nerves-project/bootloader). It's not mandatory,
but it's pretty convenient since it can handle your application crashing during
development without forcing you to re-burn an SDCard. Since other instructions
assume that it's around, update your `mix.exs` deps with it too:

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
`id_rsa.pub`, etc.  files from your `~/.ssh` directory or add something like this:

```elixir
config :nerves_firmware_ssh,
  authorized_keys: [
    File.read!(Path.join(System.user_home!, ".ssh/id_rsa.pub"))
  ]
```

That's it! Now you can do the normal Nerves development procedure for building and
installing the image to your device:

```sh
export MIX_TARGET=rpi0  # modify if necessary

# You shouldn't need to run this line unless you skipped this step
# when running `mix nerves.new` to create your project initially.
mix nerves.release.init

mix deps.get
mix firmware
mix firmware.burn
```

## Using

Give your device a few seconds to boot and initialize the virtual Ethernet
interface going through the USB cable. On your computer, run `ping` to see that
it's working:

```sh
ping nerves.local
```

If you're using Ubuntu and `ping` doesn't work, check the Network Settings for
the `usb0` interface and set the IPv4 Method to "Link-Local Only".

If the network still doesn't work, check that the virtual serial port to the
device works and see the troubleshooting section.

To update firmware from now on, just run the following:

```sh
MIX_TARGET=rpi0 mix firmware.push nerves.local
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

## Configuration

You may customize `nerves_init_gadget` using your `config.exs`:

```elixir
config :nerves_init_gadget,
  ifname: "usb0",
  address_method: :linklocal,
  mdns_domain: "nerves.local",
  node_name: nil
```

The above are the defaults and should work for most users. The following
sections go into more detail on the individual options.

#### `:ifname`

This sets the network interface to configure and monitor on the device. For
gadget use, this is almost aways `usb0`. If you'd like to use
`nerves_init_gadget` on a real Ethernet interface or WiFi, modify this to `eth0`
or `wlan0`. You'll probably want to change the `:address_method` to `:dhcp`. For
wireless use, you'll need to supply a default configuration to specify the SSID
to associate with. See the [`nerves_network`
docs](https://github.com/nerves-project/nerves_network#configuring-defaults) for
details.

#### `:address_method`

This sets how an IP address should be assigned to the network interface. If
using anything but `:linklocal` and `:dhcp`, you'll need to configure defaults
on `nerves_network` to set other parameters.

#### `:mdns_domain`

This is the mDNS name for finding the device. If you don't like `nerves.local`,
feel free to specify something else. If you set this to `nil`, mDNS will be
disabled.

#### `:node_name`

This is the node name for Erlang distribution. If specified, `epmd` will be
started and the node will be configured as `:name@host`. You'll be able to
see the node's name at the IEx prompt and it's possible to determine
programmatically by resolving `nerves.local` on a host if you need to write
something that automatically connects.

#### `:node_host`

Defaults to `:ip` which means that it will use the ip of the interface specified
in `:ifname`. You can also set this to a hostname such as the one configured in
`:mdns_domain`.

Currently only long names are supported (i.e., no snames).

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

## License

This code is licensed under the Apache License 2.0.
