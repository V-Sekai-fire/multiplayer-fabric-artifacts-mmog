defmodule ArtifactsMmog.CLI do
  @moduledoc """
  Escript entry point.

  Usage:
    artifacts_mmog tui                      # launch TUI
    artifacts_mmog status                   # print server status
    artifacts_mmog plan <char> <goal_json>  # run HTN plan for a character
  """

  def main(args) do
    case args do
      ["tui"] ->
        {:ok, _pid} = ArtifactsMmog.TUI.start_link([])
        Process.sleep(:infinity)

      ["status"] ->
        ArtifactsMmog.API.status() |> Jason.encode!(pretty: true) |> IO.puts()

      ["plan", char, goal_json] ->
        goals = Jason.decode!(goal_json)

        case ArtifactsMmog.Planner.run(char, goals) do
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
          tui                        Launch interactive TUI
          status                     Print server status
          plan <char> <goal_json>    Plan and execute goals for a character

        Environment:
          ARTIFACTS_TOKEN            Your ArtifactsMMO API token
        """)
    end
  end
end
