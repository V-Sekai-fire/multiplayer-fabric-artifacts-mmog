# AGENTS.md — multiplayer-fabric-artifacts-mmog

Guidance for AI coding agents working in this submodule.

## What this is

Elixir HTN-planning bot for the ArtifactsMMO game. It calls the game REST
API via `Req`, builds a Taskweft JSON-LD domain from live character state,
plans one episode, and executes the resulting action sequence.

Full usage, available goals, and the `adventurer.jsonld` sync contract are
documented in the root `AGENTS.md` (`## multiplayer-fabric-artifacts-mmog`
section). Read that section before making changes here.

## Build and test

```sh
mix compile
mix test
mix format --check-formatted
```

## Running the bot

```sh
# List available goals
mix artifacts_mmog.goals

# Run a goal loop (Ctrl-C to stop)
ARTIFACTS_MMOG_KEY=<token> mix artifacts_mmog.run <CharName> <goal>

# Fixed number of iterations
ARTIFACTS_MMOG_KEY=<token> mix artifacts_mmog.run <CharName> fight_chickens 10
```

## Key files

| Path | Purpose |
|------|---------|
| `mix.exs` | Dependencies: req, jason, taskweft |
| `lib/artifacts_mmog/domain.ex` | Builds Taskweft domain JSON from game state |
| `lib/artifacts_mmog/client.ex` | ArtifactsMMO REST API calls |
| `priv/plans/personas/adventurer.jsonld` | Baseline domain mirror — must stay in sync with `domain.ex` |

## Conventions

- Keep `adventurer.jsonld` in sync whenever `domain.ex` changes (op syntax,
  method set, and zone enum must all match).
- Every new `.ex` / `.exs` file needs SPDX headers:
  ```elixir
  # SPDX-License-Identifier: MIT
  # Copyright (c) 2026 K. S. Ernest (iFire) Lee
  ```
- Commit message style: sentence case, no `type(scope):` prefix.
  Example: `Add fish_trout goal to domain and adventurer persona`
