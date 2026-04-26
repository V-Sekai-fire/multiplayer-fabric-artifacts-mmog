defmodule Mix.Tasks.ArtifactsMmog.Key do
  @shortdoc "Manage the ArtifactsMMO API key in the OS keychain"
  @moduledoc """
  Store, retrieve, or delete the ArtifactsMMO Bearer token in the macOS keychain.

      mix artifacts_mmog.key set     # prompt for token and save to keychain
      mix artifacts_mmog.key get     # print the stored token
      mix artifacts_mmog.key delete  # remove the token from keychain

  The token is stored under:
    service  org.v-sekai.godot.multiplayer_fabric_mmog.api_key
    account  artifacts_mmog

  Once stored, `mix artifacts_mmog.run` will use it automatically when
  ARTIFACTS_MMOG_KEY is not set in the environment.
  """

  use Mix.Task

  alias ArtifactsMmog.Keystore

  @impl Mix.Task
  def run(["set"]) do
    token = prompt_secret("ArtifactsMMO API token")

    if token == "" do
      Mix.shell().error("No token entered.")
    else
      case Keystore.put(token) do
        :ok -> Mix.shell().info("API key stored in keychain.")
        {:error, msg} -> Mix.shell().error("Failed to store key: #{msg}")
      end
    end
  end

  def run(["get"]) do
    case Keystore.get() do
      {:ok, token} ->
        Mix.shell().info(token)

      {:error, :not_found} ->
        Mix.shell().error("No API key in keychain. Run: mix artifacts_mmog.key set")

      {:error, msg} ->
        Mix.shell().error("Failed to read key: #{msg}")
    end
  end

  def run(["delete"]) do
    case Keystore.remove() do
      :ok -> Mix.shell().info("API key removed from keychain.")
      {:error, msg} -> Mix.shell().error("Failed to delete key: #{msg}")
    end
  end

  def run(_) do
    Mix.shell().error("""
    Usage:
      mix artifacts_mmog.key set
      mix artifacts_mmog.key get
      mix artifacts_mmog.key delete
    """)
  end

  # Hides input by spawning a process that redraws the prompt over any typed
  # characters every millisecond via stderr escape sequences. IO.gets/1 blocks
  # on the actual read; the clearer stops as soon as Enter is pressed.
  defp prompt_secret(label) do
    IO.write("#{label}: ")
    pid = spawn_link(fn -> clear_loop(label) end)
    ref = make_ref()
    value = IO.gets("")
    send(pid, {:done, self(), ref})
    receive do: ({:done, ^pid, ^ref} -> :ok)
    IO.write(:standard_error, "\e[2K\r#{label}: [stored]\n")
    value |> to_string() |> String.trim()
  end

  defp clear_loop(label) do
    receive do
      {:done, parent, ref} ->
        send(parent, {:done, self(), ref})
    after
      1 ->
        IO.write(:standard_error, "\e[2K\r#{label}: ")
        clear_loop(label)
    end
  end
end
