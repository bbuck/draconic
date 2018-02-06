defmodule Draconic.Executor do
  #  def run(program_spec, args) do
  #    result =
  #      case OptionParser.parse(args, option_parser_config(flags(), aliases())) do
  #        {flags, [], invalid} ->
  #          init_execution(commands(), {flags, [@default_command], invalid})
  #
  #        parse_result ->
  #          init_execution(commands(), parse_result)
  #      end
  #
  #    case result do
  #      nil -> 0
  #      x when is_integer(x) -> x
  #      _ -> -1
  #    end
  #  end
  #
  #  defp init_execution(cmds, {flags, args, invalid} = arg_data) do
  #    IO.puts(inspect(flags))
  #
  #    if flags[:help] do
  #      run_help(flags, args, invalid)
  #    else
  #      execute_command(cmds, arg_data)
  #    end
  #  end
  #
  #  defp execute_command(cmds, {_flags, [], _invalid}), do: {:error, :nocommand}
  #
  #  defp execute_command(cmds, {flags, ["help" | args], invalid}) when @help_command do
  #    run_help(flags, args, invalid)
  #  end
  #
  #  defp execute_command(cmds, {flags, [cmd | args], invalid}) do
  #    case Map.fetch(cmds, cmd) do
  #      {:ok, spec} ->
  #        {sub_flags, _args, invalid} =
  #          OptionParser.parse(invalid, option_parser_config(spec.flags, spec.aliases))
  #
  #        flags = List.flatten([flags, sub_flags])
  #
  #        case execute_command(spec.subcommands, {flags, args, invalid}) do
  #          {:error, :nocommand} ->
  #            spec.module.run(flags_for_run(flags), args)
  #
  #          x ->
  #            x
  #        end
  #
  #      :error ->
  #        {:error, :nocommand}
  #    end
  #  end
  #
  #  defp run_help(flags, args, invalid) do
  #    help = @options.help.render(program_spec(), flags_for_run(flags), args, invalid)
  #    IO.puts(help)
  #    nil
  #  end
  #
  #  defp option_parser_config(flags, aliases) do
  #    [
  #      switches: flags,
  #      aliases: aliases
  #    ]
  #  end
  #
  #  defp flags_for_run(flags) do
  #    if @options.flag_type == :map do
  #      Draconic.Flags.to_map(flags)
  #    else
  #      flags
  #    end
  #  end
end
