defmodule Draconic.Program do
  @type options() :: %{
          flag_type: :keywords | :map,
          help: module(),
          help_flag: {atom(), atom()},
          help_command: boolean()
        }

  @type t() :: %{
          commands: [Draconic.Command.t()],
          flags: keyword(),
          options: options()
        }

  defmacro __using__(opts \\ nil) do
    main = opts == :with_main

    quote do
      import Draconic.Program

      @define_main unquote(main)

      @commands []
      @flags []
      @aliases []
      @options %{
        flag_type: :keywords,
        help: Draconic.BasicHelp,
        help_flag: {:help, :h}
      }
      @help_command true
      @default_command "help"

      @before_compile Draconic.Program
    end
  end

  defmacro default(cmd) do
    quote do
      @default_command unquote(cmd)
    end
  end

  defmacro command(mod) do
    quote do
      @commands [unquote(mod) | @commands]
    end
  end

  defmacro flag(name, type) do
    quote do
      @flags [{unquote(name), unquote(type)} | @flags]
    end
  end

  defmacro alias_flag(alias, flag) do
    quote do
      @aliases [{unquote(alias), unquote(flag)} | @aliases]
    end
  end

  defmacro flag_type(type) do
    quote do
      @options Map.put(@options, :flag_type, unquote(type))
    end
  end

  defmacro help_renderer(mod) do
    quote do
      @options Map.put(@options, :help, unquote(mod))
    end
  end

  defmacro help_flag(name, alias) do
    quote do
      @options Map.put(@options, :help_flag, {unquote(name), unquote(alias)})
    end
  end

  defmacro provide_help_command(state) do
    quote do
      @help_command state
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      defp commands do
        @commands
        |> Enum.map(fn mod -> {mod.name(), mod.command_spec()} end)
        |> Enum.into(%{})
      end

      def flags do
        {help, _} = @options.help_flag
        [{help, :boolean} | @flags]
      end

      def aliases do
        {help, alias} = @options.help_flag
        [{alias, help} | @aliases]
      end

      def options, do: @options
      def default, do: @default_command

      if @define_main do
        def main(args) do
          run(args)
        end
      end

      def program_spec do
        %{
          module: __MODULE__,
          commands: commands(),
          options: options(),
          flags: flags(),
          aliases: aliases(),
          default: default()
        }
      end

      def run(args) do
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
  end
end
