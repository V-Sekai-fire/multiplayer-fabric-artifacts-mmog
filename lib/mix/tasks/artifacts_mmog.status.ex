defmodule Mix.Tasks.ArtifactsMmog.Status do
  @shortdoc "Print ArtifactsMMO server status"
  @moduledoc "Fetch and print the current ArtifactsMMO server status as JSON."

  use Mix.Task

  @impl Mix.Task
  def run(_) do
    Mix.Task.run("app.start")
    ArtifactsMmog.API.status() |> Jason.encode!(pretty: true) |> Mix.shell().info()
  end
end
