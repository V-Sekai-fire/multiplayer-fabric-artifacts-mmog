defmodule ArtifactsMmog.TUI do
  @moduledoc """
  Terminal UI for ArtifactsMMO using ExRatatui.App.

  Shows character status, logs, and allows navigating characters.
  Refreshes every 5 seconds via handle_info tick.
  """

  use ExRatatui.App

  alias ArtifactsMmog.API
  alias ExRatatui.Layout
  alias ExRatatui.Layout.Rect
  alias ExRatatui.Style
  alias ExRatatui.Widgets.{Block, Paragraph}

  defstruct characters: [],
            logs: [],
            selected: 0,
            loading: true,
            error: nil

  @refresh_ms 5_000

  @impl true
  def mount(_opts) do
    schedule_refresh()
    send(self(), :load_data)
    {:ok, %__MODULE__{}}
  end

  @impl true
  def handle_event(%ExRatatui.Event.Key{code: code}, state) do
    case code do
      "q" -> {:stop, state}
      "r" -> send(self(), :load_data); {:noreply, %{state | loading: true}}
      "j" ->
        max = max(length(state.characters) - 1, 0)
        {:noreply, %{state | selected: min(state.selected + 1, max)}}
      "k" ->
        {:noreply, %{state | selected: max(state.selected - 1, 0)}}
      _ -> {:noreply, state}
    end
  end

  def handle_event(_event, state), do: {:noreply, state}

  @impl true
  def handle_info(:load_data, state) do
    new_state =
      try do
        chars = fetch_characters()
        logs = fetch_logs(chars)
        %{state | characters: chars, logs: logs, loading: false, error: nil}
      rescue
        e -> %{state | loading: false, error: Exception.message(e)}
      end

    schedule_refresh()
    {:noreply, new_state}
  end

  def handle_info(:refresh_tick, state) do
    send(self(), :load_data)
    {:noreply, %{state | loading: true}}
  end

  def handle_info(_msg, state), do: {:noreply, state}

  @impl true
  def terminate(_reason, _state), do: :ok

  @impl true
  def render(state, frame) do
    area = %Rect{x: 0, y: 0, width: frame.width, height: frame.height}

    [header_area, body_area, logs_area] =
      Layout.split(area, :vertical, [{:length, 3}, {:min, 0}, {:length, 8}])

    [chars_area, detail_area] =
      Layout.split(body_area, :horizontal, [{:percentage, 35}, {:percentage, 65}])

    [
      {header_widget(state), header_area},
      {chars_widget(state), chars_area},
      {detail_widget(state), detail_area},
      {logs_widget(state), logs_area}
    ]
  end

  # --- Widget builders ---

  defp header_widget(state) do
    status =
      cond do
        state.error -> "Error: #{state.error}"
        state.loading -> "Loading..."
        true -> "OK — press [r] refresh  [j/k] select  [q] quit"
      end

    %Paragraph{
      text: "ArtifactsMMO Multiplayer Fabric  |  #{status}",
      block: %Block{title: "Status", borders: [:all]},
      style: header_style(state)
    }
  end

  defp header_style(%{error: e}) when not is_nil(e), do: %Style{fg: :red}
  defp header_style(%{loading: true}), do: %Style{fg: :yellow}
  defp header_style(_), do: %Style{fg: :green}

  defp chars_widget(%{characters: []}) do
    %Paragraph{
      text: "No characters found.\nSet ARTIFACTS_TOKEN env var.",
      block: %Block{title: "Characters", borders: [:all]},
      wrap: true
    }
  end

  defp chars_widget(%{characters: chars, selected: sel}) do
    lines =
      chars
      |> Enum.with_index()
      |> Enum.map_join("\n", fn {c, i} ->
        prefix = if i == sel, do: "▶ ", else: "  "
        name = c["name"] || "?"
        hp = "#{c["hp"] || 0}/#{c["max_hp"] || 0}"
        "#{prefix}#{name}  #{hp} HP"
      end)

    %Paragraph{
      text: lines,
      block: %Block{title: "Characters", borders: [:all]},
      wrap: false
    }
  end

  defp detail_widget(%{characters: [], selected: _}) do
    %Paragraph{text: "", block: %Block{title: "Details", borders: [:all]}}
  end

  defp detail_widget(%{characters: chars, selected: sel}) do
    char = Enum.at(chars, sel, %{})

    text =
      [
        "Name     : #{char["name"]}",
        "Level    : #{char["level"]}",
        "HP       : #{char["hp"]}/#{char["max_hp"]}",
        "Gold     : #{char["gold"]}",
        "Position : (#{char["x"]}, #{char["y"]})",
        "Task     : #{char["task"] || "none"}",
        "",
        "Inventory:",
        format_inventory(char["inventory"] || [])
      ]
      |> Enum.join("\n")

    %Paragraph{
      text: text,
      block: %Block{title: "Details", borders: [:all]},
      wrap: true
    }
  end

  defp logs_widget(%{logs: []}) do
    %Paragraph{text: "No logs.", block: %Block{title: "Recent Logs", borders: [:all]}}
  end

  defp logs_widget(%{logs: logs}) do
    text =
      logs
      |> Enum.take(5)
      |> Enum.map_join("\n", &format_log/1)

    %Paragraph{
      text: text,
      block: %Block{title: "Recent Logs", borders: [:all]},
      wrap: true
    }
  end

  defp format_inventory([]), do: "  (empty)"

  defp format_inventory(items) do
    items
    |> Enum.map(fn i -> "  #{i["code"]} x#{i["quantity"]}" end)
    |> Enum.join("\n")
  end

  defp format_log(%{"description" => desc, "created_at" => ts}), do: "[#{ts}] #{desc}"
  defp format_log(l), do: inspect(l)

  # --- Data loading ---

  defp fetch_characters do
    case API.my_characters() do
      %{"data" => chars} when is_list(chars) -> chars
      _ -> []
    end
  end

  defp fetch_logs([]), do: []

  defp fetch_logs([first | _]) do
    name = first["name"] || ""

    case API.my_logs(name, page: 1, size: 5) do
      %{"data" => logs} when is_list(logs) -> logs
      _ -> []
    end
  end

  defp schedule_refresh, do: Process.send_after(self(), :refresh_tick, @refresh_ms)
end
