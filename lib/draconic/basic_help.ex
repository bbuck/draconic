defmodule Draconic.BasicHelp do
  @behaviour Draconic.HelpRenderer

  def render(program, _flags, args, _invalid) do
    render(program, args)
  end

  defp render(spec, []) do
    inspect(spec)
  end

  defp render(%{commands: cmds} = spec, [cmd | args]) do
    case Map.fetch(cmds, cmd) do
      {:ok, cmd_spec} ->
        render(cmd_spec, args)

      :error ->
        inspect(spec)
    end
  end

  defp render(%{subcommands: cmds} = spec, [cmd | args]) do
    case Map.fetch(cmds, cmd) do
      {:ok, cmd_spec} ->
        render(cmd_spec, args)

      :error ->
        inspect(spec)
    end
  end
end
