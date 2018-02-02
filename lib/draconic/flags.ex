defmodule Draconic.Flags do
  @type flag_value() :: String.t() | integer() | float()

  @type flag_values() :: flag_value() | [flag_value()]

  @type t() :: %{optional(String.t()) => flag_values()}

  @spec to_map(keyword()) :: t()
  def to_map(flags) do
    flags
    |> build_map()
    |> adjust_lists()
    |> Enum.into(%{})
  end

  @spec build_map(keyword()) :: t()
  defp build_map(flags) do
    Enum.reduce(flags, %{}, fn {flag, val}, map ->
      case Map.fetch(map, flag) do
        {:ok, flag_val} when is_list(flag_val) ->
          Map.put(map, flag, [val | flag_val])

        {:ok, flag_val} ->
          Map.put(map, flag, [val, flag_val])

        :error ->
          Map.put(map, flag, val)
      end
    end)
  end

  @spec adjust_lists(t()) :: keyword()
  defp adjust_lists(flag_map) do
    Enum.map(flag_map, fn
      {key, val} when is_list(val) ->
        {key, Enum.reverse(val)}

      entry ->
        entry
    end)
  end
end
