defmodule ArtifactsMmog.Keystore do
  @moduledoc """
  Elixir port of ZoneConsole.FabricMMOGKeyStore, adapted for a plain API token.

  Persists the ArtifactsMMO Bearer token in the OS keychain via
  ArtifactsMmog.Keychain. Unlike the original (which stores AES-128 key + GCM
  IV with a 24-hour TTL), an API token is just a string and has no TTL here —
  the server rejects it when it expires.

  Constants mirror the C++ / zone-console definitions:
    PACKAGE = "org.v-sekai.godot"
    SERVICE = "multiplayer_fabric_mmog.api_key"
  """

  alias ArtifactsMmog.Keychain

  @doc """
  Persist the API token. Overwrites any existing entry.
  Returns :ok or {:error, message}.
  """
  @spec put(String.t()) :: :ok | {:error, String.t()}
  def put(token) when is_binary(token) and byte_size(token) > 0 do
    Keychain.set_password(token)
  end

  @doc """
  Retrieve the stored API token.
  Returns {:ok, token} | {:error, :not_found} | {:error, message}.
  """
  @spec get() :: {:ok, String.t()} | {:error, :not_found | String.t()}
  def get do
    Keychain.get_password()
  end

  @doc """
  Remove the stored token. Idempotent — returns :ok even if nothing was stored.
  """
  @spec remove() :: :ok | {:error, String.t()}
  def remove do
    Keychain.delete_password()
  end
end
