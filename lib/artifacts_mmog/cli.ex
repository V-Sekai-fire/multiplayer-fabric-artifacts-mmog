defmodule ArtifactsMmog.CLI do
  @moduledoc """
  Escript entry point.

  Commands:
    artifacts_mmog tui                       # launch TUI
    artifacts_mmog status                    # print server status
    artifacts_mmog run <char> <goal>         # continuous game loop
    artifacts_mmog plan <char> <goal_json>   # one-shot HTN plan (raw tasks JSON)
    artifacts_mmog goals                     # list available goals
  """

  def main(args) do
    case args do
      ["tui"] ->
        {:ok, _pid} = ArtifactsMmog.TUI.start_link([])
        Process.sleep(:infinity)

      ["status"] ->
        ArtifactsMmog.API.status() |> Jason.encode!(pretty: true) |> IO.puts()

      ["goals"] ->
        ArtifactsMmog.Runner.goals()
        |> Enum.sort()
        |> Enum.each(&IO.puts("  #{&1}"))

      ["run", char, goal] ->
        IO.puts("Starting loop: #{char} → #{goal}  (Ctrl-C to stop)")
        ArtifactsMmog.Runner.run(char, goal)

      ["run", char, goal, n] ->
        IO.puts("Running #{n} iterations: #{char} → #{goal}")
        ArtifactsMmog.Runner.run(char, goal, max_iterations: String.to_integer(n))

      ["plan", char, tasks_json] ->
        tasks = Jason.decode!(tasks_json)

        case ArtifactsMmog.Planner.run(char, tasks) do
          {:ok, results} ->
            Enum.each(results, fn {action, result} ->
              IO.puts("#{action}: #{inspect(result)}")
            end)

          {:error, reason} ->
            IO.puts("Error: #{reason}")
        end

      _ ->
        IO.puts("""
        ArtifactsMMO Multiplayer Fabric Agent

        Commands:
          tui                         Launch interactive TUI
          status                      Print server status
          goals                       List available goals
          run <char> <goal>           Continuous farming/fighting loop
          run <char> <goal> <n>       Run N iterations then stop
          plan <char> <tasks_json>    One-shot plan from raw task array

        Goals: farm_copper, farm_iron, farm_coal, farm_ash, farm_birch,
               farm_spruce, farm_sunflowers, fight_chickens, fight_pigs,
               fight_goblins, fight_wolverines, fish_gudgeon, task_cycle

        Environment:
          ARTIFACTS_TOKEN             Your ArtifactsMMO API token

        Examples:
          ARTIFACTS_TOKEN=... ./artifacts_mmog run MyChar farm_copper
          ARTIFACTS_TOKEN=... ./artifacts_mmog run MyChar fight_chickens 10
        """)
    end
  end
end
