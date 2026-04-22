defmodule ArtifactsMmog.MixProject do
  use Mix.Project

  def project do
    [
      app: :artifacts_mmog,
      version: "0.1.0",
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {ArtifactsMmog.Application, []}
    ]
  end

  defp deps do
    [
      {:taskweft, github: "V-Sekai-fire/multiplayer-fabric-taskweft"},
      {:req, "~> 0.5"},
      {:jason, "~> 1.4"}
    ]
  end
end
