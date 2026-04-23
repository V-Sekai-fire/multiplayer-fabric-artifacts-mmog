defmodule ArtifactsMmog do
  @moduledoc """
  Multiplayer Fabric agent for ArtifactsMMO (https://www.artifactsmmo.com/).

  - `ArtifactsMmog.API`     — REST client (move, fight, gather, rest, tasks)
  - `ArtifactsMmog.Domain`  — HTN domain builder; maps live character state to Taskweft JSON
  - `ArtifactsMmog.Planner` — fetch → plan → execute one episode
  - `ArtifactsMmog.Runner`  — continuous goal loop with retry

  ## Usage

      # List available goals
      mix artifacts_mmog.goals

      # Run a continuous loop (Ctrl-C to stop)
      ARTIFACTS_MMOG_KEY=... mix artifacts_mmog.run Aria fight_chickens

      # Run N iterations
      ARTIFACTS_MMOG_KEY=... mix artifacts_mmog.run Aria farm_copper 10

  Set `ARTIFACTS_MMOG_KEY` to your ArtifactsMMO API bearer token.
  """
end
