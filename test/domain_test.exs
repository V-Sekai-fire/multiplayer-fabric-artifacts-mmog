defmodule ArtifactsMmog.DomainTest do
  use ExUnit.Case

  # RED: zone_for_pos currently returns 99 for unmapped coords; must return bank_id.
  test "zone_for_pos falls back to bank_id for Aria's actual position (2, -4)" do
    assert ArtifactsMmog.Domain.zone_for_pos(2, -4) == ArtifactsMmog.Domain.bank_id()
  end

  test "zone_for_pos falls back to bank_id for any unmapped position" do
    assert ArtifactsMmog.Domain.zone_for_pos(999, 999) == ArtifactsMmog.Domain.bank_id()
  end

  # RED: Domain.build/2 must not embed zone 99 when character is at an unmapped position.
  test "build/2 starting zone is bank_id when character position is unmapped" do
    char = %{"name" => "hero", "hp" => 100, "max_hp" => 100,
             "x" => 2, "y" => -4, "task" => "", "inventory" => [],
             "inventory_max_items" => 100}
    json = ArtifactsMmog.Domain.build(char, [])
    {:ok, decoded} = Jason.decode(json)
    zone_var = Enum.find(decoded["variables"], & &1["name"] == "zone")
    assert zone_var["init"]["hero"] == ArtifactsMmog.Domain.bank_id()
  end
end
