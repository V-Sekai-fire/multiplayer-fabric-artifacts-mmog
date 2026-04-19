defmodule ArtifactsMmog do
  @moduledoc """
  Multiplayer Fabric agent for ArtifactsMMO (https://www.artifactsmmo.com/).

  Combines:
  - `ArtifactsMmog.API`     — REST client for the ArtifactsMMO API
  - `ArtifactsMmog.Planner` — HTN planning via Taskweft
  - `ArtifactsMmog.TUI`     — ex_ratatui terminal UI
  - `ArtifactsMmog.CLI`     — escript entry point

  Set `ARTIFACTS_TOKEN` env var to your API token before running.
  """
end
