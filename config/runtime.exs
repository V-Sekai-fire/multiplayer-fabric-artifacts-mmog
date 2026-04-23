import Config

dotenv = Path.expand("../.env", __DIR__)

if File.exists?(dotenv) do
  dotenv
  |> File.read!()
  |> String.split("\n", trim: true)
  |> Enum.reject(&String.starts_with?(&1, "#"))
  |> Enum.each(fn line ->
    case String.split(line, "=", parts: 2) do
      [k, v] when byte_size(k) > 0 ->
        if is_nil(System.get_env(k)), do: System.put_env(k, v)
      _ ->
        :ok
    end
  end)
end
