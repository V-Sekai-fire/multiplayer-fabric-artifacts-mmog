defmodule ArtifactsMmogTest do
  use ExUnit.Case

  test "build_domain produces valid JSON" do
    char = %{"name" => "hero", "hp" => 80, "max_hp" => 100, "x" => 0, "y" => 0,
              "level" => 1, "gold" => 0, "inventory" => []}
    goals = [%{"type" => "fight"}]
    json = ArtifactsMmog.Planner.build_domain(char, goals)
    assert {:ok, decoded} = Jason.decode(json)
    assert decoded["domain"] == "artifacts_mmog"
    assert decoded["state"]["hp"] == 80
  end
end
