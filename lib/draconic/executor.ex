defmodule Draconic.Executor do
  alias Draconic.Program

  @spec execute(Program.t(), Program.argv()) :: Program.status_code()
  def execute(program_spec, args) do
    {flags, rest_args} = parse_options(program_spec.flags, args)
  end

  # parse arguments into flags/commands from scratch
  defp parse_options(flags, args) do
    flag_opts = Flag.to_options(flags)
    parse_options(flag_opts, args, {%{}, []})
  end

  # parse arguments into flags/commands with exisiting parsed flags
  defp parse_options(flags, args, %{} = parsed_flags) do
    flag_opts = Flag.to_options(flags)
    parse_options(flag_opts, args, {parsed_flags, []})
  end

  defp parse_options(_flag_opts, [], {flags, ret_args}), do: {flags, List.reverse(ret_args)}

  defp parse_options(flag_opts, args, {flags, rest_args}) do
    case OptionParser.next(args, flag_opts) do
      {:ok, key, value, remaining} ->
        flags = Map.put(flags, key, value)
        parse_options(flag_opts, remaining, {flags, rest_args})

      {:undefined, key, nil, remaining} ->
        rest_args = [key | rest_args]
        parse_options(flag_opts, remaining, {flags, rest_args})

      {:invalid, key, value, remaining} ->
        IO.write(:stderr, "ERROR: invalid value \"#{value}\" given for #{key}")

      {:error, []} ->
        parse_options(flag_opts, [], {flags, rest_args})

      {:error, [cmd | remaining]} ->
        rest_args = [cmd | rest_args]
        parse_options(flag_opts, remaining, {flags, rest_args})
    end
  end


  # COPIED OVER

   def run(program_spec, args) do
     result =
       case OptionParser.parse(args, option_parser_config(flags(), aliases())) do
         {flags, [], invalid} ->
           init_execution(commands(), {flags, [@default_command], invalid})

         parse_result ->
           init_execution(commands(), parse_result)
       end

     case result do
       nil -> 0
       x when is_integer(x) -> x
       _ -> -1
     end
   end

   defp init_execution(cmds, {flags, args, invalid} = arg_data) do
     IO.puts(inspect(flags))

     if flags[:help] do
       run_help(flags, args, invalid)
     else
       execute_command(cmds, arg_data)
     end
   end

   defp execute_command(cmds, {_flags, [], _invalid}), do: {:error, :nocommand}

   defp execute_command(cmds, {flags, ["help" | args], invalid}) when @help_command do
     run_help(flags, args, invalid)
   end

   defp execute_command(cmds, {flags, [cmd | args], invalid}) do
     case Map.fetch(cmds, cmd) do
       {:ok, spec} ->
         {sub_flags, _args, invalid} =
           OptionParser.parse(invalid, option_parser_config(spec.flags, spec.aliases))

         flags = List.flatten([flags, sub_flags])

         case execute_command(spec.subcommands, {flags, args, invalid}) do
           {:error, :nocommand} ->
             spec.module.run(flags_for_run(flags), args)

           x ->
             x
         end

       :error ->
         {:error, :nocommand}
     end
   end

   defp run_help(flags, args, invalid) do
     help = @options.help.render(program_spec(), flags_for_run(flags), args, invalid)
     IO.puts(help)
     nil
   end

   defp option_parser_config(flags, aliases) do
     [
       switches: flags,
       aliases: aliases
     ]
   end

   defp flags_for_run(flags) do
     if @options.flag_type == :map do
       Draconic.Flags.to_map(flags)
     else
       flags
     end
   end
end
