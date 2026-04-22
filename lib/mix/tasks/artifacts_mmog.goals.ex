defmodule Mix.Tasks.ArtifactsMmog.Goals do
  @shortdoc "List available goals"
  @moduledoc "Print all valid goal names for use with `mix artifacts_mmog.run`."

  use Mix.Task

  @impl Mix.Task
  def run(_) do
    ArtifactsMmog.Runner.goals()
    |> Enum.sort()
    |> Enum.each(&Mix.shell().info("  #{&1}"))
  end
end
