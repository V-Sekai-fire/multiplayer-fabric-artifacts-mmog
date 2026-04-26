defmodule Mix.Tasks.ArtifactsMmog.Run do
  @shortdoc "Run a goal loop for a character"
  @moduledoc """
  Run a continuous farming/fighting loop for a character.

      mix artifacts_mmog.run <char> <goal>
      mix artifacts_mmog.run <char> <goal> <n>

  Examples:

      mix artifacts_mmog.run Aria fight_chickens
      mix artifacts_mmog.run Aria farm_copper 10

  The API token is read from the OS keychain. Store it once with:

      mix artifacts_mmog.key set

  Run `mix artifacts_mmog.goals` to list available goals.
  """

  use Mix.Task

  @impl Mix.Task
  def run([char, goal]) do
    Mix.Task.run("app.start")
    ArtifactsMmog.Runner.run(char, goal)
  end

  def run([char, goal, n]) do
    Mix.Task.run("app.start")
    ArtifactsMmog.Runner.run(char, goal, max_iterations: String.to_integer(n))
  end

  def run(_), do: Mix.shell().error("Usage: mix artifacts_mmog.run <char> <goal> [n]")
end
