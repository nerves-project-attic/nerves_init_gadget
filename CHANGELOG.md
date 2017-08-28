# Changelog

## v0.2.1

  * Bug fixes
    * Work around a multicast registration issue on wireless links. This adds
      a 100ms delay to starting up mDNS which appears to fix it for now.
      See https://github.com/fhunleth/nerves_init_gadget/pull/7

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
