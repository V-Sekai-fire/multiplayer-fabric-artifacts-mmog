defmodule ArtifactsMmog.RunnerTest do
  use ExUnit.Case

  # RED: stub returns :goblins for all levels; correct answer is :chickens for lvl 1-4.
  test "combat_zone_for_level returns :chickens for level 1" do
    assert ArtifactsMmog.Runner.combat_zone_for_level(1) == :chickens
  end

  test "combat_zone_for_level returns :chickens for level 4" do
    assert ArtifactsMmog.Runner.combat_zone_for_level(4) == :chickens
  end

  test "combat_zone_for_level returns :goblins for level 5" do
    assert ArtifactsMmog.Runner.combat_zone_for_level(5) == :goblins
  end

  test "combat_zone_for_level returns :wolverines for level 10" do
    assert ArtifactsMmog.Runner.combat_zone_for_level(10) == :wolverines
  end
end
