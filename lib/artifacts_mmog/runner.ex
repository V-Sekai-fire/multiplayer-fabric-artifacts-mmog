defmodule ArtifactsMmog.Runner do
  @moduledoc """
  Continuous game loop: fetch state → plan episode → execute → repeat.

  Each iteration plans one "batch" (e.g. 5 gathers or 5 fights).
  The loop continues until `:max_iterations` is reached or the process is killed.
  """

  alias ArtifactsMmog.{Domain, Planner}

  @goals %{
    farm_copper:      ["farm_resources", :copper_rocks],
    farm_iron:        ["farm_resources", :iron_rocks],
    farm_coal:        ["farm_resources", :coal_rocks],
    farm_ash:         ["farm_resources", :ash_trees],
    farm_birch:       ["farm_resources", :birch_trees],
    farm_spruce:      ["farm_resources", :spruce_trees],
    farm_sunflowers:  ["farm_resources", :sunflowers],
    fight_chickens:   ["fight_monsters", :chickens],
    fight_pigs:       ["fight_monsters", :pigs],
    fight_goblins:    ["fight_monsters", :goblins],
    fight_wolverines: ["fight_monsters", :wolverines],
    fish_gudgeon:     ["farm_resources", :gudgeon],
    task_cycle:       ["task_cycle"]
  }

  def goals, do: Map.keys(@goals)

  @doc """
  Select the appropriate combat zone for a character's level.
  """
  def combat_zone_for_level(level) when level < 5,  do: :chickens
  def combat_zone_for_level(level) when level < 10, do: :goblins
  def combat_zone_for_level(_level),                do: :wolverines

  @doc """
  Run a goal loop for `char_name`.

  Options:
    - `:max_iterations` — stop after N plans (default: `:infinity`)
    - `:delay_ms` — ms to sleep between iterations (default: 500)
  """
  def run(char_name, goal, opts \\ []) when is_atom(goal) or is_binary(goal) do
    goal = if is_binary(goal), do: String.to_existing_atom(goal), else: goal
    unless Map.has_key?(@goals, goal) do
      raise ArgumentError, "unknown goal #{inspect(goal)}, valid: #{inspect(Map.keys(@goals))}"
    end
    max  = Keyword.get(opts, :max_iterations, :infinity)
    delay = Keyword.get(opts, :delay_ms, 500)
    loop(char_name, goal, 0, max, delay)
  end

  # ---------------------------------------------------------------------------

  defp loop(_, _, n, max, _) when is_integer(max) and n >= max, do: {:ok, n}
  defp loop(char_name, goal, n, max, delay) do
    IO.puts("[Runner] #{char_name} | #{goal} | iteration #{n + 1}")

    case step(char_name, goal) do
      {:ok, steps} ->
        IO.puts("[Runner] executed #{length(steps)} step(s)")
        Process.sleep(delay)
        loop(char_name, goal, n + 1, max, delay)

      {:error, "no_plan"} ->
        IO.puts("[Runner] no plan found — waiting 10s")
        Process.sleep(10_000)
        loop(char_name, goal, n + 1, max, delay)

      {:error, reason} ->
        IO.puts("[Runner] error: #{reason} — waiting 5s")
        Process.sleep(5_000)
        loop(char_name, goal, n + 1, max, delay)
    end
  end

  defp step(char_name, goal) do
    Planner.run(char_name, build_tasks(goal, char_name))
  end

  defp build_tasks(goal, char_name) do
    case @goals[goal] do
      ["farm_resources", zone] -> [["farm_resources", char_name, Domain.zone_id(zone)]]
      ["fight_monsters", zone] -> [["fight_monsters", char_name, Domain.zone_id(zone)]]
      ["task_cycle"]           -> [["task_cycle", char_name]]
    end
  end

end
