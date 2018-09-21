# Changelog

## v0.5.2

* Enhancements
  * Use `:dhcpd` instead of `:linklocal` for defaults.
  * Load `/etc/iex.exs` on ssh connections

## v0.5.1

* New features
  * SFTP support

## v0.5.0

* New features
  * When using Erlang distribution, the node's hostname can be set to the name
    returned by DHCP: `node_host: :dhcp`
  * SSH console access is enabled by default now. Disable by setting
    `ssh_console_port: nil`
  * To address issues with link-local networking, it's now possible to run a
    mini DHCP server to supply an IP address instead. Enable by setting
   `address_method: :dhcpd`.  See
   [OneDHCPD](https://github.com/fhunleth/one_dhcpd) for more information.

* Bug fixes
  * Merge `default` configs from `nerves_network`. This fixes an issue where
    `wlan0` settings were lost.

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
