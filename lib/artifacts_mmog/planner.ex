defmodule ArtifactsMmog.Planner do
  @moduledoc """
  HTN planning for ArtifactsMMO characters via Taskweft.

  Builds a JSON-LD domain from the current character state and goals,
  runs the planner, then executes each step against the REST API.
  """

  alias ArtifactsMmog.API

  @doc """
  Build a domain JSON-LD document from character state and a goal list.
  Goals are maps like %{type: "fight", target: "chicken"} etc.
  """
  def build_domain(character, goals) do
    state = character_to_state(character)

    domain = %{
      "@context" => "https://taskweft.schema/v1",
      "domain" => "artifacts_mmog",
      "state" => state,
      "goal" => goals,
      "methods" => methods(),
      "operators" => operators()
    }

    Jason.encode!(domain)
  end

  @doc """
  Plan and execute goals for the named character.
  Returns {:ok, results} or {:error, reason}.
  """
  def run(char_name, goals) do
    with %{"data" => char} <- API.my_characters(),
         character <- find_character(char, char_name),
         domain_json <- build_domain(character, goals),
         {:ok, plan_json} <- Taskweft.plan(domain_json) do
      plan = Jason.decode!(plan_json)
      execute_plan(char_name, plan)
    end
  end

  # --- Private ---

  defp find_character(chars, name) when is_list(chars),
    do: Enum.find(chars, fn c -> c["name"] == name end) || %{}
  defp find_character(_, _), do: %{}

  defp character_to_state(char) do
    %{
      "hp" => char["hp"] || 0,
      "max_hp" => char["max_hp"] || 100,
      "x" => char["x"] || 0,
      "y" => char["y"] || 0,
      "level" => char["level"] || 1,
      "gold" => char["gold"] || 0,
      "inventory" => char["inventory"] || []
    }
  end

  defp execute_plan(char_name, steps) do
    results =
      Enum.map(steps, fn [action | args] ->
        result = dispatch(char_name, action, args)
        maybe_cooldown(result)
        {action, result}
      end)

    {:ok, results}
  end

  defp dispatch(name, "move", [x, y]), do: API.move(name, x, y)
  defp dispatch(name, "fight", []), do: API.fight(name)
  defp dispatch(name, "gather", []), do: API.gather(name)
  defp dispatch(name, "rest", []), do: API.rest(name)
  defp dispatch(name, "craft", [code | rest]) do
    qty = List.first(rest, 1)
    API.craft(name, code, qty)
  end
  defp dispatch(name, action, args) do
    %{"error" => "unknown action #{action}", "args" => args, "character" => name}
  end

  defp maybe_cooldown(%{"data" => %{"cooldown" => %{"remaining_seconds" => secs}}})
       when secs > 0,
       do: Process.sleep(trunc(secs * 1000))
  defp maybe_cooldown(_), do: :ok

  defp methods do
    [
      %{
        "name" => "fight_until_full_hp",
        "preconditions" => [%{"hp_lt_max" => true}],
        "subtasks" => [["rest"], ["fight"]]
      },
      %{
        "name" => "go_gather",
        "preconditions" => [],
        "subtasks" => [["gather"]]
      }
    ]
  end

  defp operators do
    [
      %{"name" => "move", "params" => ["x", "y"]},
      %{"name" => "fight", "params" => []},
      %{"name" => "gather", "params" => []},
      %{"name" => "rest", "params" => []},
      %{"name" => "craft", "params" => ["code", "quantity"]}
    ]
  end
end
