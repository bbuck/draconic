defmodule Draconic.Program do
  @moduledoc """
  Draconic is a DSL for building command line programs. It allows you to define your
  CLI via simplistic macro functions that get compiled into simple modules used at 
  run time to execute the desired command users enter. It's built on top of the
  built in `OptionParser` so it's flag definitions are a remnant of those supported
  by `OptionParser`. Although the goal was to unify aspects of an option flag as 
  singular unit.

  With Draconic commands are defined as their own modules, and as behaviors you 
  just implement the run method that will be invoked if the command is given.
  Associating these commands to a program is a simple call to a macro passing in the
  module defining the command.

  Commands in Draconic function like a tree, supporting nested (or "sub") commands
  with their own set of flags. Flags are parsed from top to bottom, following the
  path of commands, so global flags are parsed, the flags for the first command,
  the second and down to the nth. So the lowest command executed (the only one the
  `run` method will be called for) has access to all flags defined before it.

  #### Examples

  Define a program.

      defmodule CSVParser.CLI do
        use Draconic.Program

        alias CSVParser.CLI.Commands

        name "awesome"
        
        command Commands.Mapper
        command Commands.Lister
      end

  Configure your escipt program.

      defmodule CSVParser.MixProject do
        # ...
        def escript do
          [
            main_module: CSVParser.CLI
          ]
        end
        # ...
      end

  Then just execute your program!

      csv_parser list --input example.csv

  """

  alias __MODULE__
  alias Draconic.Command
  alias Draconic.Flag

  @typedoc "A list of string values passed into the program."
  @type argv() :: [String.t()]

  @typedoc "The return value from CLI, `0` (or `nil`) or a non-zero error code."
  @type status_code() :: integer() || nil

  @typedoc """
  Contains the definition of a program, from things like it's description to a 
  map of commands available to be executed and even what default command should
  be executed if none is given. This struct is not only used to execute a program
  but it's also provided to a HelpRenderer which can then render help pages however
  it decides to do so.
  """
  @type t() :: %Program{
          module: module(),
          name: String.t(),
          usage: String.t() | nil,
          description: String.t(),
          commands: [Command.t()],
          flags: Flag.flag_definition(),
          help_renderer: module(),
          help_command: true
        }

  @doc false
  defstruct module: nil,
            name: "",
            commands: [],
            usage: nil,
            description: "",
            flags: %{},
            default_command: "help",
            help_renderer: Draconic.BasicHelp,
            help_command: true

  @doc false
  defmacro __using__(_) do
    quote do
      import Draconic.Program

      @name "PROGRAM"
      @commands []
      @usage
      @description ""
      @flags %{}
      @help_renderer Draconic.BasicHelp
      @help_flag_name {:help, :h}
      @help_command true
      @default_command "help"

      @before_compile Draconic.Program
    end
  end

  @doc "Set the name of the program, used in auto-usage generation."
  @spec name(String.t()) :: Macro.t()
  defmacro name(name) do
    quote do
      @name unquote(name)
    end
  end

  @doc "Set the programs description, used in help rendering."
  @spec desc(String.t()) :: Macro.t()
  defmacro desc(description) do
    quote do
      @description unquote(description)
    end
  end

  @doc """
  Explicitly set a usage string. This may or may not be considered by
  the help renderer.
  """
  @spec usage(String.t()) :: Macro.t()
  defmacro usage(usage) do
    quote do
      @usage unquote(usage)
    end
  end

  @doc "Define a command to use when no other command is given."
  @spec default_command(String.t()) :: Macro.t()
  defmacro default_command(cmd) do
    quote do
      @default_command unquote(cmd)
    end
  end

  @doc "Add a command module to the program."
  @spec command(module()) :: Macro.t()
  defmacro command(mod) do
    quote do
      @commands [unquote(mod) | @commands]
    end
  end

  @doc """
  Creates a string flag with the given name, description and default value associated
  the currently defined program.
  """
  @spec string_flag(Flag.flag_name(), String.t(), Flag.flag_type()) :: Macro.t()
  defmacro string_flag(name, description, default) do
    quote do
      flag(unquote(name), :string, unquote(description), unquote(default))
    end
  end

  @doc """
  Creates a integer flag with the given name, description and default value associated
  the currently defined program.
  """
  @spec int_flag(Flag.flag_name(), String.t(), Flag.flag_type()) :: Macro.t()
  defmacro int_flag(name, description, default \\ nil) do
    quote do
      flag(unquote(name), :integer, unquote(description), unquote(default))
    end
  end

  @doc """
  Creates a float flag with the given name, description and default value associated
  the currently defined program.
  """
  @spec float_flag(Flag.flag_name(), String.t(), Flag.flag_type()) :: Macro.t()
  defmacro float_flag(name, description, default \\ nil) do
    quote do
      flag(unquote(name), :float, unquote(description), unquote(default))
    end
  end

  @doc """
  Creates a bool flag with the given name, description and default value associated
  the currently defined program.
  """
  @spec bool_flag(Flag.flag_name(), String.t(), Flag.flag_type()) :: Macro.t()
  defmacro bool_flag(name, description, default \\ nil) do
    quote do
      flag(unquote(name), :boolean, unquote(description), unquote(default))
    end
  end

  @doc """
  Creates a flag of the given type, with the given name, description and default value
  (if provided) and associates it to the root program.
  """
  @spec flag(Flag.flag_name(), Flag.flag_kind(), String.t(), Flag.flag_type()) :: Macro.t()
  defmacro flag(name, type, description, default \\ nil) do
    {fname, falias} =
      case name do
        {n, a} -> {n, a}
        x -> {x, nil}
      end

    quote do
      @flags Map.put(@flags, unquote(fname), %Flag{
               name: unquote(fname),
               alias: unquote(falias),
               type: unquote(type),
               description: unquote(description),
               default: unquote(default)
             })
    end
  end

  @doc "Assign a help renderer module for this program, defaults to Draconic.BasicHelp"
  @spec help_renderer(module()) :: Macrot.t()
  defmacro help_renderer(mod) do
    quote do
      @help_renderer unquote(mod)
    end
  end

  @doc "Provide a name (and potential alias) for the help command, defaults to `{:help, :h}`"
  @spec help_flag(Flag.flag_name()) :: Macrot.t()
  defmacro help_flag(name) do
    quote do
      @help_flag_name unquote(name)
    end
  end

  @doc """
  Turn on, or off, the help command. If this value is `true` (default value) then running
  the program with the command "help" (or the value you set for it) will render the help
  page. Even if this is turned off, you can still use "help" (or a value you give for it)
  as the default command.
  """
  @spec provide_help_command(boolean()) :: Macro.t()
  defmacro provide_help_command(state) do
    quote do
      @help_command unquote(state)
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      defp commands do
        @commands
        |> Enum.map(fn mod -> {mod.name(), mod.command_spec()} end)
        |> Enum.into(%{})
      end

      def help_flag_name do
        case @help_flag_name do
          {name, _} -> name
          x -> x
        end
      end

      def flags do
        {help_name, help_alias} = @help_flag_name

        help = %Flag{
          name: help_name,
          alias: help_alias,
          type: :boolean,
          description: "Print this page, providing useful information about the program.",
          default: false
        }

        Map.put(@flags, help_name, help)
      end

      def default_command, do: @default_command

      def help_renderer, do: @help_renderer

      def help_command, do: @help_command

      def program_spec do
        %Program{
          name: @name,
          description: @description,
          usage: @usage,
          module: __MODULE__,
          commands: commands(),
          flags: flags(),
          default_command: default_command(),
          help_renderer: help_renderer(),
          help_command: help_command()
        }
      end

      # TODO: docs
      @spec main(argv()) :: status_code()
      def main(args) do
        Draconic.Executor.execute(program_spec(), args)
      end
    end
  end
end
