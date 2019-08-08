[
  # Dialyzer doesn't like us calling Process.link on the opaque ssh
  # daemon reference. How are we supposed to handle it or us crashing if
  # we can't link??
  {"lib/nerves_init_gadget/ssh_console.ex", :no_return},
  {"lib/nerves_init_gadget/ssh_console.ex", :call_with_opaque}
]
