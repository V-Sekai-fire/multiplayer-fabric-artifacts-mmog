# Contributing

An Elixir mix application for running ArtifactsMMO characters — farming,
fighting, and task cycles — built on `taskweft` for HTN planning and `req`
for HTTP. Follows red-green-refactor discipline.

Built strictly red-green-refactor: every feature is driven by a failing
test, committed when green, then any cleanup is done with the test
still green.

## Guiding principles

- **RED first, always.** Before writing implementation code write a
  test that fails.  Confirm the failure is for the right reason before
  writing the fix.
- **Error tuples, not exceptions.** All boundary functions return
  `{:ok, value}` / `{:error, reason}`.  `raise` is reserved for
  programmer errors (wrong argument type, missing config at boot).
  HTTP errors are always `{:error, _}` tuples propagated to the caller.
- **Commit every green.** One commit per feature cycle.

## Workflow

```
mix deps.get
mix test                                       # run ExUnit suite
mix artifacts_mmog.goals                       # list available goals
ARTIFACTS_TOKEN=... mix artifacts_mmog.run Aria fight_chickens
ARTIFACTS_TOKEN=... mix artifacts_mmog.run Aria farm_copper 10
```

## Mix tasks

| Task | Description |
|------|-------------|
| `mix artifacts_mmog.goals` | List all valid goal names |
| `mix artifacts_mmog.run <char> <goal>` | Continuous loop until Ctrl-C |
| `mix artifacts_mmog.run <char> <goal> <n>` | Run exactly N iterations |
| `mix artifacts_mmog.status` | Print server status JSON |

## Environment

```
ARTIFACTS_TOKEN   Your ArtifactsMMO API bearer token
```

## Design notes

### Planning loop

Each iteration: fetch live character state → build HTN domain JSON
(`Domain.build/2`) → plan via `Taskweft.plan/1` → execute steps
(`Planner.execute/2`). `Runner` owns the retry loop; `Planner` owns
the single fetch→build→plan→execute cycle.

### Zone IDs

Zone coordinates are compile-time constants in `Domain.@zones`. Unknown
positions fall back to `bank_id` (zone 0). `combat_zone_for_level/1` in
`Runner` selects the appropriate combat zone by character level.
