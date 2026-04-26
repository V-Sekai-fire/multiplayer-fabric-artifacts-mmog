defmodule ArtifactsMmog.Keychain do
  @moduledoc """
  macOS Security.framework access via the `security` CLI.

  Mirrors the interface of ZoneConsole.Keychain but without a Rust NIF —
  delegates to the system `security` binary so no native build is required.

  Constants match the zone-console / C++ keychain namespace:
    PACKAGE = "org.v-sekai.godot"
    SERVICE = "multiplayer_fabric_mmog.api_key"
  """

  @package "org.v-sekai.godot"
  @service "multiplayer_fabric_mmog.api_key"
  @account "artifacts_mmog"

  # macOS errSecItemNotFound exit code from the security CLI
  @err_not_found 44

  @doc "Returns {:ok, password} | {:error, :not_found} | {:error, message}."
  @spec get_password() :: {:ok, String.t()} | {:error, :not_found | String.t()}
  def get_password do
    case System.cmd(
           "security",
           ["find-generic-password", "-a", @account, "-s", service_name(), "-w"],
           stderr_to_stdout: false
         ) do
      {password, 0} -> {:ok, String.trim(password)}
      {_, @err_not_found} -> {:error, :not_found}
      {msg, _} -> {:error, String.trim(msg)}
    end
  end

  @doc "Returns :ok | {:error, message}. Overwrites any existing entry."
  @spec set_password(String.t()) :: :ok | {:error, String.t()}
  def set_password(password) when is_binary(password) do
    case System.cmd(
           "security",
           ["add-generic-password", "-U", "-a", @account, "-s", service_name(), "-w", password],
           stderr_to_stdout: true
         ) do
      {_, 0} -> :ok
      {msg, _} -> {:error, String.trim(msg)}
    end
  end

  @doc "Returns :ok (idempotent — deleting a missing entry is not an error)."
  @spec delete_password() :: :ok | {:error, String.t()}
  def delete_password do
    case System.cmd("security", ["delete-generic-password", "-a", @account, "-s", service_name()],
           stderr_to_stdout: true
         ) do
      {_, 0} -> :ok
      {_, @err_not_found} -> :ok
      {msg, _} -> {:error, String.trim(msg)}
    end
  end

  # mirrors makeServiceName: package <> "." <> service
  defp service_name, do: @package <> "." <> @service
end
