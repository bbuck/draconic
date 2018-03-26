defmodule Draconic.BasicHelp do
  alias Draconic.Program
  alias Draconic.Command

  @behaviour Draconic.HelpRenderer

  @typep spec_t :: Program.t() | Command.t()

  def render(program, _flags, args, _invalid) do
    inspect(get_spec(program, args))
  end

  @spec get_spec(spec_t(), Program.argv()) :: spec_t()
  defp get_spec(spec, []), do: spec

  @spec get_spec(Program.t(), Program.argv()) :: spec_t()
  defp get_spec(%Program{commands: cmds} = spec, [cmd | args]) do
    case Map.fetch(cmds, cmd) do
      {:ok, cmd_spec} ->
        get_spec(cmd_spec, args)

      :error ->
        spec
    end
  end

  @spec get_spec(Command.t(), Program.argv()) :: spec_t()
  defp get_spec(%Command{subcommands: sub_cmds} = spec, [cmd | args]) do
    case Map.fetch(sub_cmds, cmd) do
      {:ok, cmd_spec} ->
        get_spec(cmd_spec, args)

      :error ->
        spec
    end
  end
end
