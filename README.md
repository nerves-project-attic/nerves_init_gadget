# nerves_init_gadget

[![Hex version](https://img.shields.io/hexpm/v/nerves_init_gadget.svg "Hex version")](https://hex.pm/packages/nerves_init_gadget)

This project provides the basics for getting started with Nerves. This includes
bringing up networking, over-the-air firmware updates and many other little
things that make using Nerves a little better. At some point your project may
outgrow `nerves_init_gadget` and when that happens, you can use it as an
example.

By design, this project is mostly dependences and only a little bit of "glue"
code. Here's a summary of what you get:

* Link-local networking for devices that can connect via a USB gadget interface
  like the Raspberry Pi Zero and Beaglebone boards.
* mDNS support to advertise a name like `nerves.local`
* Device detection, filesystem mounting, and basic device control from `nerves_runtime`
* Over-the-air firmware updates using `nerves_firmware_ssh`
* Easy setup of Erlang distribution to support remsh, Observer and other debug
  and tracing tools
* Access to the IEx console via `ssh`
* IEx helpers for a happier commandline experience
* Logging via [ring_logger](https://github.com/nerves-project/ring_logger)
* [shoehorn](https://github.com/nerves-project/shoehorn)-aware instructions to
  reduce the number of SDCard reprogrammings that you need to do in regular
  development.

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
mix archive.install hex nerves_bootstrap
```

Create a new project using the generator:

```sh
mix nerves.new mygadget
```

Add `nerves_init_gadget` to the deps in the `mix.exs`:

```elixir
  defp deps(target) do
    [
      {:nerves_runtime, "~> 0.4"},
      {:nerves_init_gadget, "~> 0.3"}
    ] ++ system(target)
  end
```

Now add `nerves_init_gadget` to the list of applications to always start. If you
haven't used `shoehorn` before, it separates the application initialization
into phases to isolate failures. This lets us ensure that `nerves_init_gadget`
runs even if we messed up something in our application code. It's useful during
development so that you can send firmware updates to devices with broken
software. Take a look at your `config/config.exs` and edit the `:shoehorn`
config to look something like this:

```elixir
config :shoehorn,
  init: [:nerves_runtime, :nerves_init_gadget],
  app: Mix.Project.config()[:app]
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

By itself, this does not allow you to log into your device using `ssh`. This is
only for sending firmware updates to the device. (The `ssh` protocol is really
cool and lets you do more than just connect to shells.) If you'd like to connect
to the IEx prompt, see the [:ssh_console_port](#ssh_console_port) configuration
option.

The last change to the `config.exs` is to replace the default Elixir logger with
[ring_logger](https://github.com/nerves-project/ring_logger). Eventually you may
want to persist logs or send them to a server, but for now this keeps them
around in memory so that you can review them even if you're not connected when
the messages are sent.

```elixir
config :logger, backends: [RingLogger]
```

Finally, run the usual Elixir and Nerves build steps:

```sh
# Modify for your board
export MIX_TARGET=rpi0

mix deps.get
mix firmware

# Copy the firmware to a MicroSD card (or change this to how you do the
# first-time load of software onto your device.)
mix firmware.burn
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
[shoehorn](https://github.com/nerves-project/shoehorn). It's not mandatory,
but it's pretty convenient since it can handle your application crashing during
development without forcing you to re-burn an SDCard. Since other instructions
assume that it's around, update your `mix.exs` deps with it too:

```elixir
def deps do
  [
    {:shoehorn, "~> 0.2"},
    {:nerves_init_gadget, "~> 0.3"}
  ]
end
```

Shoehorn requires a plugin to the
[distillery](https://github.com/bitwalker/distillery) configuration, so add it
to your `rel/config.exs` (replace `:your_app`):

```elixir
release :your_app do
  plugin Shoehorn
  ...
end
```

Now, add the following configuration to your `config/config.exs`:

```elixir
config :shoehorn,
  init: [:nerves_runtime, :nerves_init_gadget],
  app: Mix.Project.config()[:app]
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

The last change to the `config.exs` is to enable
[ring_logger](https://github.com/nerves-project/ring_logger). Like many aspects
of `nerves_init_gadget`, this is optional and you can use the default Elixir
logger or a logger of your choosing if you'd like.

```elixir
config :logger, backends: [RingLogger]
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

Connect your device over the USB port with your computer (if using a RPi0, it
is very important to use the port labeled "USB" and not the one labeled "PWR").
Give your device a few seconds to boot and initialize the virtual Ethernet
interface going through the USB cable. On your computer, run `ping` to see that
it's working:

```sh
ping nerves.local
```

If you're using Ubuntu and `ping` doesn't work, check the Network Settings for
the `usb0` interface and set the IPv4 Method to "Link-Local Only". Depending on
your kernel settings for "Predictable Network Interface Naming", the interface
might be called `enp0s26u1u2` or some variation thereof. Be aware that the
`NetworkManager` tool may have trouble holding on to configured settings for
this network interface between unplugging and replugging.

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

If you have your private key stored in a file with a different name than `id_dsa`,
`id_rsa`, or `identity`, chances are that `mix firmware push` will not find them.
Use `upload.sh` in this case as well.

## Configuration

You may customize `nerves_init_gadget` using your `config.exs`:

```elixir
config :nerves_init_gadget,
  ifname: "usb0",
  address_method: :linklocal,
  mdns_domain: "nerves.local",
  node_name: nil,
  node_host: :mdns_domain
```

The above are the defaults and should work for most users. The following
sections go into more detail on the individual options.

### `:ifname`

This sets the network interface to configure and monitor on the device. For
gadget use, this is almost aways `usb0`. If you'd like to use
`nerves_init_gadget` on a real Ethernet interface or WiFi, modify this to `eth0`
or `wlan0`. You'll probably want to change the `:address_method` to `:dhcp`. For
wireless use, you'll need to supply a default configuration to specify the SSID
to associate with. See the [`nerves_network`
docs](https://github.com/nerves-project/nerves_network#configuring-defaults) for
details.

### `:address_method`

This sets how an IP address should be assigned to the network interface. If
using anything but `:linklocal` and `:dhcp`, you'll need to configure defaults
on `nerves_network` to set other parameters.

### `:mdns_domain`

This is the mDNS name for finding the device. It defaults to `nerves.local`.
This is very convenient when there's only one device on the network.

If you don't want mDNS, set this to `nil`.

You can set this to `:hostname` and the mDNS name will be set to the
`hostname.local`. The official Nerves systems all generate semi-unique hostnames
for devices. This makes it possible to discover devices via mDNS and also to
connect to them. Note that if your network uses DHCP, Nerves lists its hostname
in the DHCP request so if your router supports it, you may be able to connect to
the device via the hostname as well.

### `:node_name`

This is the node name for Erlang distribution. If specified (non-nil),
`nerves_init_gadget` will start `epmd` and configure the node as
`:<name>@<host>`. See the next option for the `host` part.

Currently only long names are supported (i.e., no snames).

### `:node_host`

This is the host part of the node name when using Erlang distribution. You may
specify a string to use as a host name or one of the following atoms:

* `:ip` - Set the host part to `:ifname`'s assigned IP address.
* `:mdns_domain` Set the host part to the value advertised by mDNS.

The default is `:mdns_domain` so that the following remsh invocation works:

```bash
iex --name me@0.0.0.0 --cookie acookie --remsh node_name@nerves.local
```

### `:ssh_console_port`

If specified (non-nil), `nerves_init_gadget` will start an IEx console on the
specified port. This console will use the same ssh public keys as those
configured for `:nerves_firmware_ssh`. For example, if you set
`ssh_console_port: 22`, rebuild and update the firmware. Usernames are ignored,
so you can ssh to the device just by running:

```bash
ssh nerves.local
```

To exit the SSH session, type `~.`. This is an `ssh` escape sequence (See the
[ssh man page](https://linux.die.net/man/1/ssh) for other escape sequences).
Typing `Ctrl+D` or `logoff` at the IEx prompt to exit the session aren't
implemented.

## Troubleshooting

If things aren't working, try the following to figure out what's wrong:

1. Check that you're plugged into the right USB port on the target. The
   Raspberry Pi Zero, for example, has two USB ports but one of them is only for
   power.
2. Check that the USB cable works (some cables are power-only and don't have the
   data lines hooked up). Try connecting to the virtual serial port using
   `picocom` or `screen` to get to the IEx prompt. Depending on your host system
   the virtual serial port may be named `/dev/ttyUSB0`, `/dev/ttyACM0`, or some
   variation of that.
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

## FAQ

### What should I put in my config for Raspberry Pi 3 w/ wired Ethernet

Try this if you're on a DHCP-enabled network:

```elixir
config :nerves_init_gadget,
  ifname: "eth0",
  address_method: :dhcp,
  node_name: "murphy"
```

This also starts up Erlang distribution with a node name of "murphy". Get your
cookie from `rel/vm.args` (look for the `-setcookie` line) and run the following
to connect to your device:

```bash
iex --name me@0.0.0.0 --cookie acookie --remsh murphy@nerves.local
```

### How do I register a callback before the system reboots

If you need to save data or notify the user of an impending reboot or power off,
take a look at OTP's
[`Application.stop/1`](https://hexdocs.pm/elixir/Application.html#c:stop/1) and
[`Application.prep_stop/1`](https://hexdocs.pm/elixir/Application.html#c:prep_stop/1)
callbacks. Reboots and shutdowns initiated through
[`Nerves.Runtime.reboot/0`](https://hexdocs.pm/nerves_runtime/Nerves.Runtime.html#reboot/0)
or
[`Nerves.Runtime.poweroff/0`](https://hexdocs.pm/nerves_runtime/Nerves.Runtime.html#poweroff/0)
have a timer that restricts how long the OTP shut down process can take. This
prevents shutdown hangs. The timer duration is specified in
[`erlinit.config`](https://hexdocs.pm/nerves/advanced-configuration.html#overwriting-files-in-the-root-filesystem).

### Why do I see `x\360~` when I reboot

You may also see things like this:

```elixir
x\360~
** (SyntaxError) iex:4: invalid sigil delimiter: "\360" (column 3, codepoint U+00F0). The available delimiters are: //, ||, "", '', (), [], {}, <>
```

You're probably also using Linux. This is
[ModemManager](https://www.freedesktop.org/wiki/Software/ModemManager/) probing
the serial port to see if there's a modem. ModemManager prevents anything from
using the serial port until it gives up on finding a modem at the other end.
This takes a second or two and leaves junk behind at the IEx prompt.

Check out the ModemManager description to see whether this software is even
something that you want. Here's a popular solution:

```bash
sudo apt remove modemmanager
```

## License

This code is licensed under the Apache License 2.0.
