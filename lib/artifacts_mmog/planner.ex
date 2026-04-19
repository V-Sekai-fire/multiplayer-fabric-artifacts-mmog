defmodule ArtifactsMmog.Planner do
  @moduledoc """
  HTN planning execution for ArtifactsMMO.

  Use `ArtifactsMmog.Domain.build/2` to produce the domain JSON,
  then `Taskweft.plan/1` to get a plan, then `execute/2` here to run it.
  `run/2` combines all three steps in one call.
  """

  alias ArtifactsMmog.{API, Domain}

  @doc """
  Plan and execute one episode for `char_name` toward `tasks`.

  `tasks` is a list of `[method, arg, ...]` arrays passed to `Domain.build/2`.
  Returns `{:ok, results}` or `{:error, reason}`.
  """
  def run(char_name, tasks) do
    with {:ok, char}     <- fetch_char(char_name),
         domain_json     <- Domain.build(char, tasks),
         {:ok, plan_json} <- Taskweft.plan(domain_json),
         {:ok, plan}     <- Jason.decode(plan_json) do
      execute(char_name, plan)
    end
  end

  @doc """
  Execute an already-decoded plan (list of `[action, arg, ...]` steps).
  """
  def execute(char_name, steps) do
    results =
      Enum.map(steps, fn [action | args] ->
        IO.puts("[Planner] #{action}(#{Enum.join(args, ", ")})")
        result = dispatch(char_name, action, args)
        maybe_cooldown(result)
        {action, result}
      end)

    {:ok, results}
  end

  # ---------------------------------------------------------------------------
  # Private
  # ---------------------------------------------------------------------------

  defp fetch_char(name) do
    case API.my_characters() do
      %{"data" => chars} when is_list(chars) ->
        case Enum.find(chars, &(&1["name"] == name)) do
          nil  -> {:error, "character #{name} not found"}
          char -> {:ok, char}
        end
      other ->
        {:error, "API error: #{inspect(other)}"}
    end
  end

  defp dispatch(name, "a_move", [_char, zone_id]) do
    zone_int = trunc_zone(zone_id)
    case Domain.zone_coords(zone_int) do
      {x, y} -> API.move(name, x, y)
      nil    -> %{"error" => "unknown zone id #{zone_id}"}
    end
  end

  defp dispatch(name, "a_gather",        [_char | _]), do: API.gather(name)
  defp dispatch(name, "a_fight",         [_char | _]), do: API.fight(name)
  defp dispatch(name, "a_rest",          [_char | _]), do: API.rest(name)
  defp dispatch(name, "a_accept_task",   [_char | _]), do: API.accept_task(name)
  defp dispatch(name, "a_complete_task", [_char | _]), do: API.complete_task(name)

  defp dispatch(name, "a_bank_deposit", [_char | _]) do
    API.deposit_all(name)
  end

  defp dispatch(name, action, args) do
    IO.puts("[Planner] unknown action: #{action}(#{Enum.join(inspect(args), ", ")})")
    %{"error" => "unknown action #{action}", "character" => name}
  end

  defp trunc_zone(id) when is_integer(id), do: id
  defp trunc_zone(id) when is_float(id), do: trunc(id)
  defp trunc_zone(id) when is_binary(id), do: String.to_integer(id)

  defp maybe_cooldown(%{"data" => %{"cooldown" => %{"remaining_seconds" => secs}}})
       when is_number(secs) and secs > 0,
       do: Process.sleep(trunc(secs * 1000))
  defp maybe_cooldown(_), do: :ok
end
