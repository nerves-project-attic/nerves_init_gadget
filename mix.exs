defmodule Nerves.InitGadget.Mixfile do
  use Mix.Project

  def project do
    [app: :nerves_init_gadget,
     name: "Nerves Init Gadget",
     description: "Easy Nerves initialization for devices with USB gadget interfaces",
     author: "Frank Hunleth",
     version: "0.1.0",
     elixir: "~> 1.4",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps()]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    # Specify extra applications you'll use from Erlang/Elixir
    [extra_applications: [:logger],
     mod: {Nerves.InitGadget.Application, []}]
  end

  # Dependencies can be Hex packages:
  #
  #   {:my_dep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:my_dep, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [{:nerves_runtime, "~> 0.3"},
     {:nerves_network, github: "nerves-project/nerves_network"},
     {:nerves_firmware_ssh, github: "fhunleth/nerves_firmware_ssh"},
     {:exjsx, "~> 4.0"},
     {:mdns, github: "mobileoverlord/mdns", branch: "linklocal"}]
  end
end
