# Nerves.InitGadget

This project adds a basic level of setup for Nerves devices with USB gadget mode
interfaces like the Raspberry Pi Zero. Here are some features:

* Automatically sets up link local networking on the USB interface. No DHCP or
  static IP setup needed on the host laptop
* Sets up MDNS to respond to lookups for `nerves.local`
* Pulls in the `nerves_runtime` initialization for things like mounting and
  fixing the application filesystem
* Starts `nerves_firmware_http` so that push firmware updates work
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
    {:nerves_init_gadget, github: "fhunleth/nerves_init_gadget", branch: "master"}
  ]
end
```

Bootloader requires a plugin to the
[distillery](https://github.com/bitwalker/distillery) configuration, so add
it to your `rel/config.exs` (replace `:your_app`):

```elixir
release :your_app do
  plugin Bootloader.Plugin
  ...
end
```

Finally, add the following configuration to your `config/config.exs` (replace
`:your_app)`:

```elixir
# Boot the bootloader first and have it start our app.
config :bootloader,
  init: [:nerves_init_zero],
  app: :your_app
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
$ mix firmware.push nerves.local
```

Assuming everything completes succesfully, the device will reboot with the new
firmware.

