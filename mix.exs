defmodule Nerves.InitGadget.Mixfile do
  use Mix.Project

  @version "0.2.0"

  @description """
  Easy Nerves initialization for devices with USB gadget interfaces
  """

  def project do
    [app: :nerves_init_gadget,
     version: @version,
     description: @description,
     package: package(),
     elixir: "~> 1.4",
     docs: docs(),
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps()]
  end

  def application() do
    [extra_applications: [:logger],
     mod: {Nerves.InitGadget.Application, []}]
  end

  defp package() do
    %{maintainers: ["Frank Hunleth"],
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => "https://github.com/fhunleth/nerves_init_gadget"}}
  end

  defp docs() do
    [main: "readme",
     extras: ["README.md"]]
  end

  defp deps() do
    [{:nerves_runtime, "~> 0.3"},
     {:nerves_network, "~> 0.3"},
     {:nerves_firmware_ssh, "~> 0.2"},
     {:mdns, "~> 0.1"},
     {:ex_doc, "~> 0.11", only: :dev}]
  end
end
