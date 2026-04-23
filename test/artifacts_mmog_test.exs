defmodule ArtifactsMmogTest do
  use ExUnit.Case

  test "Planner.execute/2 handles unknown action without crashing" do
    {:ok, results} = ArtifactsMmog.Planner.execute("hero", [["unknown_action", "arg1", 2]])
    assert [{_action, %{"error" => _}}] = results
  end

  test "Domain.build/2 produces valid JSON with correct name and hp variable" do
    char = %{"name" => "hero", "hp" => 80, "max_hp" => 100, "x" => 0, "y" => 0,
             "task" => "", "inventory" => [], "inventory_max_items" => 100}
    json = ArtifactsMmog.Domain.build(char, [])
    assert {:ok, decoded} = Jason.decode(json)
    assert decoded["name"] == "artifacts_mmog"
    hp_var = Enum.find(decoded["variables"], & &1["name"] == "hp")
    assert hp_var["init"]["hero"] == 80
  end
end
