defmodule Nerves.InitGadget.Options do
  @moduledoc false

  defstruct ifname: "usb0",
            address_method: :linklocal,
            mdns_domain: "nerves.local",
            node_name: nil,
            node_host: :mdns_domain,
            ssh_console_port: nil
end
