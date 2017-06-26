defmodule NervesInitZero.Mixfile do
  use Mix.Project

  def project do
    [app: :nerves_init_zero,
     name: "Nerves Init Zero",
     description: "Easy Nerves base setup of a Raspberry Pi Zero",
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
     mod: {Nerves.InitZero.Application, []}]
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
     {:nerves_network, git: "https://github.com/nerves-project/nerves_network.git", branch: "master"},
     {:mdns, "~> 0.1.5"}]
  end
end
