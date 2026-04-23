defmodule ArtifactsMmog.Domain do
  @moduledoc """
  ArtifactsMMO HTN domain definition for Taskweft.

  Zone IDs are stable integer indices into the `@zones` list.
  Coordinates are approximate defaults for the main starting area.
  """

  @zones [
    {:bank,          {4,  1}},
    {:copper_rocks,  {2,  0}},
    {:iron_rocks,    {1,  5}},
    {:coal_rocks,    {1,  6}},
    {:ash_trees,     {-1, 0}},
    {:birch_trees,   {3,  5}},
    {:spruce_trees,  {2,  6}},
    {:sunflowers,    {2,  1}},
    {:chickens,      {0,  1}},
    {:pigs,          {5,  2}},
    {:goblins,       {-1, 1}},
    {:wolverines,    {2, -1}},
    {:gudgeon,       {4,  2}},
    {:task_master,   {1,  2}}
  ]

  @zone_enum @zones
    |> Enum.with_index()
    |> Map.new(fn {{name, _}, idx} -> {Atom.to_string(name), idx} end)

  @zone_id_to_coords @zones
    |> Enum.with_index()
    |> Map.new(fn {{_, coords}, idx} -> {idx, coords} end)

  @zone_coords_to_id @zones
    |> Enum.with_index()
    |> Map.new(fn {{_, {x, y}}, idx} -> {{x, y}, idx} end)

  @bank_id Map.fetch!(@zone_enum, "bank")
  @task_master_id Map.fetch!(@zone_enum, "task_master")

  def zone_id(name) when is_atom(name), do: @zone_enum[Atom.to_string(name)]
  def zone_id(name) when is_binary(name), do: @zone_enum[name]
  def zone_id(id) when is_integer(id), do: id

  def zone_coords(id), do: @zone_id_to_coords[id]

  def zone_for_pos(x, y), do: @zone_coords_to_id[{x, y}] || @bank_id

  def bank_id, do: @bank_id
  def task_master_id, do: @task_master_id

  @doc """
  Build a Taskweft JSON-LD domain string from a character map and a tasks list.

  `tasks` is a list of `[method_name, arg, ...]` arrays, e.g.:
    `[["farm_resources", "MyChar", 1]]`
  """
  def build(char, tasks) do
    char_name = char["name"] || "char"
    zone_id   = zone_for_pos(char["x"] || 0, char["y"] || 0)
    inv_count = (char["inventory"] || []) |> Enum.reject(&is_nil/1) |> length()
    inv_max   = char["inventory_max_items"] || 100
    has_task  = if char["task"] && char["task"] != "", do: 1, else: 0

    %{
      "@context" => %{
        "khr" => "https://registry.khronos.org/glTF/extensions/2.0/KHR_interactivity/",
        "domain" => "khr:planning/domain/"
      },
      "@type"   => "domain:Definition",
      "name"    => "artifacts_mmog",
      "enums"   => %{"zone" => @zone_enum},
      "variables" => [
        %{"name" => "zone",      "init" => %{char_name => zone_id}},
        %{"name" => "hp",        "init" => %{char_name => char["hp"]     || 100}},
        %{"name" => "max_hp",    "init" => %{char_name => char["max_hp"] || 100}},
        %{"name" => "inv_count", "init" => %{char_name => inv_count}},
        %{"name" => "inv_max",   "init" => %{char_name => inv_max}},
        %{"name" => "has_task",  "init" => %{char_name => has_task}}
      ],
      "actions"  => actions(),
      "methods"  => methods(),
      "tasks"    => tasks
    }
    |> Jason.encode!()
  end

  # ---------------------------------------------------------------------------
  # Actions — primitive operators that mutate state.
  # ---------------------------------------------------------------------------

  defp actions do
    %{
      # Move character to a named zone (int enum id).
      "a_move" => %{
        "params" => ["char", "dest"],
        "body"   => [%{"set" => "/zone/{char}", "value" => "{dest}"}]
      },

      # Gather one item. Fails if inventory is full.
      "a_gather" => %{
        "params" => ["char"],
        "bind"   => [%{"name" => "imax", "pointer" => "/inv_max/{char}"}],
        "body"   => [
          %{"check" => "/inv_count/{char}", "lt" => "{imax}"},
          %{"set"   => "/inv_count/{char}",
            "value" => %{"op" => "add",
                         "a"  => %{"op" => "get", "pointer" => "/inv_count/{char}"},
                         "b"  => 1}}
        ]
      },

      # Fight one monster. Requires hp > 0.
      "a_fight" => %{
        "params" => ["char"],
        "body"   => [%{"check" => "/hp/{char}", "ge" => 1}]
      },

      # Rest to full hp.
      "a_rest" => %{
        "params" => ["char"],
        "body"   => [%{"set" => "/hp/{char}",
                       "value" => %{"op" => "get", "pointer" => "/max_hp/{char}"}}]
      },

      # Deposit all items at bank. Character must be at bank zone.
      "a_bank_deposit" => %{
        "params" => ["char"],
        "body"   => [
          %{"check" => "/zone/{char}", "eq" => @bank_id},
          %{"set"   => "/inv_count/{char}", "value" => 0}
        ]
      },

      # Accept a task at the task master. Requires no active task.
      "a_accept_task" => %{
        "params" => ["char"],
        "body"   => [
          %{"check" => "/zone/{char}",    "eq" => @task_master_id},
          %{"check" => "/has_task/{char}", "eq" => 0},
          %{"set"   => "/has_task/{char}", "value" => 1}
        ]
      },

      # Complete current task at task master.
      "a_complete_task" => %{
        "params" => ["char"],
        "body"   => [
          %{"check" => "/zone/{char}",    "eq" => @task_master_id},
          %{"check" => "/has_task/{char}", "eq" => 1},
          %{"set"   => "/has_task/{char}", "value" => 0}
        ]
      }
    }
  end

  # ---------------------------------------------------------------------------
  # Methods — abstract tasks decomposed into primitive actions.
  # ---------------------------------------------------------------------------

  defp methods do
    %{
      # Navigate to bank (no-op if already there).
      "go_to_bank" => %{
        "params" => ["char"],
        "alternatives" => [
          %{"name"      => "already_there",
            "check"     => [%{"pointer" => "/zone/{char}", "eq" => @bank_id}],
            "subtasks"  => []},
          %{"name"      => "travel",
            "subtasks"  => [["a_move", "{char}", @bank_id]]}
        ]
      },

      # Rest if not at full HP (uses bind to compare hp vs max_hp).
      "ensure_rested" => %{
        "params" => ["char"],
        "alternatives" => [
          %{"name"     => "hp_full",
            "bind"     => [%{"name" => "mhp", "pointer" => "/max_hp/{char}"}],
            "check"    => [%{"pointer" => "/hp/{char}", "ge" => "{mhp}"}],
            "subtasks" => []},
          %{"name"     => "rest_first",
            "subtasks" => [["a_rest", "{char}"]]}
        ]
      },

      # Bank if inventory is full (uses bind to compare inv_count vs inv_max).
      "bank_if_full" => %{
        "params" => ["char"],
        "alternatives" => [
          %{"name"     => "has_space",
            "bind"     => [%{"name" => "imax", "pointer" => "/inv_max/{char}"}],
            "check"    => [%{"pointer" => "/inv_count/{char}", "lt" => "{imax}"}],
            "subtasks" => []},
          %{"name"     => "deposit",
            "subtasks" => [["go_to_bank", "{char}"], ["a_bank_deposit", "{char}"]]}
        ]
      },

      # Gather 5 items at a resource zone, banking first if inventory is full.
      "farm_resources" => %{
        "params" => ["char", "zone_id"],
        "alternatives" => [
          %{"name"     => "batch",
            "subtasks" => [
              ["bank_if_full",  "{char}"],
              ["a_move",        "{char}", "{zone_id}"],
              ["a_gather",      "{char}"],
              ["a_gather",      "{char}"],
              ["a_gather",      "{char}"],
              ["a_gather",      "{char}"],
              ["a_gather",      "{char}"]
            ]}
        ]
      },

      # Fight 5 monsters at a zone, resting and banking first as needed.
      "fight_monsters" => %{
        "params" => ["char", "zone_id"],
        "alternatives" => [
          %{"name"     => "batch",
            "subtasks" => [
              ["ensure_rested", "{char}"],
              ["bank_if_full",  "{char}"],
              ["a_move",        "{char}", "{zone_id}"],
              ["a_fight",       "{char}"],
              ["a_fight",       "{char}"],
              ["a_fight",       "{char}"],
              ["a_fight",       "{char}"],
              ["a_fight",       "{char}"]
            ]}
        ]
      },

      # Go to bank and rest to full HP — safe idle state.
      "rest_at_bank" => %{
        "params" => ["char"],
        "alternatives" => [
          %{"name"     => "safe",
            "subtasks" => [
              ["go_to_bank",    "{char}"],
              ["ensure_rested", "{char}"]
            ]}
        ]
      },

      # Accept a task (bank first), or complete if one is active.
      "task_cycle" => %{
        "params" => ["char"],
        "alternatives" => [
          %{"name"     => "accept",
            "check"    => [%{"pointer" => "/has_task/{char}", "eq" => 0}],
            "subtasks" => [
              ["go_to_bank",    "{char}"],
              ["a_bank_deposit","{char}"],
              ["a_move",        "{char}", @task_master_id],
              ["a_accept_task", "{char}"]
            ]},
          %{"name"     => "complete",
            "check"    => [%{"pointer" => "/has_task/{char}", "eq" => 1}],
            "subtasks" => [
              ["a_move",          "{char}", @task_master_id],
              ["a_complete_task", "{char}"]
            ]}
        ]
      }
    }
  end
end
