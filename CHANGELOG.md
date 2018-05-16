# Changelog

## v0.4.0

* New features
  * Added support for `ssh`-ing to an IEx prompt. To use this, add:
    `ssh_console_port: 22` to your `nerves_init_gadget` configuration.
  * Added an option for generating more unique mDNS names. If you specify
    `:hostname` for the `:mdns_domain` option, it will generate the `.local`
    name from the hostname. This lets you have names like `nerves-1234.local`
    being advertised on the network.

## v0.3.0

* New features
  * Pulled in project rename of bootloader to shoehorn. Be sure to update your
    `config/config.exs` and `rel/config.exs` references to bootloader.
  * Add dependency on `ring_logger` and instructions for setting it up since it
    fixes many of the reported issues when getting started with the console
    logger.

* Bug fixes
  * Removed many Elixir 1.5/1.6 warnings by updating dependencies

## v0.2.1

* Bug fixes
  * Work around a multicast registration issue on wireless links. This adds
    a 100ms delay to starting up mDNS which appears to fix it for now.
    See [PR #7](https://github.com/fhunleth/nerves_init_gadget/pull/7)

## v0.2.0

The README.md and other documentation has been updated to make it easier for new
Nerves users to get started with `nerves_init_gadget` and also to reflect
changes to the Nerves new project generator.

* New features
  * Network interface, mDNS name, etc. are now configurable
  * Add support for automatically starting Erlang distribution. This is not
    enabled by default.

## v0.1.0

Initial release
