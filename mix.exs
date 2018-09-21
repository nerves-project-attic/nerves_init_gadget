defmodule Nerves.InitGadget.MixProject do
  use Mix.Project

  @version "0.5.2"

  @description """
  Simple initialization for devices running Nerves
  """

  def project do
    [
      app: :nerves_init_gadget,
      version: @version,
      description: @description,
      package: package(),
      elixir: "~> 1.6",
      docs: docs(),
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application() do
    [extra_applications: [:logger], mod: {Nerves.InitGadget.Application, []}]
  end

  defp package() do
    %{
      maintainers: ["Frank Hunleth"],
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => "https://github.com/nerves-project/nerves_init_gadget"}
    }
  end

  defp docs() do
    [main: "readme", extras: ["README.md"]]
  end

  defp deps() do
    [
      {:nerves_runtime, "~> 0.3"},
      {:nerves_network, "~> 0.3"},
      {:nerves_firmware_ssh, "~> 0.2"},
      {:mdns, "~> 1.0"},
      {:ring_logger, "~> 0.4"},
      {:one_dhcpd, "~> 0.1"},
      {:ex_doc, "~> 0.19", only: [:dev, :test], runtime: false}
    ]
  end
end
