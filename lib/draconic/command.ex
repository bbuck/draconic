defmodule Draconic.Command do
  @moduledoc ~s"""
  Define a command that is executed by request of the user of the program. Commands
  are a set of local flags, subcommands and an execution content (the run function)
  to process data when called upon.

  Defining commands is easy, using the Command DSL and then integrating with a program
  is jsut as simple using it's DSL.

  A command is required to have a name, and define a run method -- this is all that's
  required in order for a command to be used.

  #### Examples
  
      defmodule MyCommand do
        name "my_command"

        bool_flag {:verbose, :v}, "Print everything."
  
        def run(flags, args) do
          if flags.verbose do
            IO.puts("Everything")
            Worker.do_the_thing()
          else
            Worker.do_the_thing()
          end
        end
      end

  This command can be used via `PROGRAM my_command -v`, this executes the `run/2` defined
  in the command.
  """
  alias __MODULE__
  alias Draconic.Program
  alias Draconic.UnnamedCommandError
  alias Draconic.Flag

  @typedoc """
  Defines a map of names to commands, used for command lookup.
  """
  @type command_map() :: %{required(String.t()) => %Command{}}

  @typedoc """
  Represents a command in the program, technically all commands are "sub-commands" of
  anoter where the top level just tracks those commands with the root as their parent.
  """
  @type t() :: %Command{
          module: module(),
          name: String.t(),
          description: String.t(),
          short_description: String.t(),
          flags: Flag.flag_definition(),
          subcommands: command_map()
        }

  @doc false
  defstruct module: nil,
            name: nil,
            description: "",
            short_description: "",
            flags: %{},
            subcommands: %{}

  @callback run(Flag.flag_map(), Program.argv()) :: Program.status_code()
  @callback command_spec() :: t()

  @doc false
  defmacro __using__(_opts) do
    quote do
      import Draconic.Command

      @behaviour Draconic.Command

      @name nil
      @description ""
      @short_description ""
      @flags %{}
      @subcommands []

      @before_compile Draconic.Command
    end
  end

  @doc "Set the name of the command, used when running the programe."
  @spec name(String.t()) :: Macro.t()
  defmacro name(name) do
    quote do
      @name unquote(name)
    end
  end

  @doc "Set the long description of the command, useful when rendering help."
  @spec desc(String.t()) :: Macro.t()
  defmacro desc(description) do
    quote do
      @description unquote(description)
    end
  end

  @doc "Set the short description for a command."
  @spec short_desc(String.t()) :: Macro.t()
  defmacro short_desc(short_desc) do
    quote do
      @short_description unquote(short_desc)
    end
  end

  @doc "Add a command as a subcommand to this command."
  @spec subcommand(module()) :: Macro.t()
  defmacro subcommand(module) do
    quote do
      @subcommands [unquote(module) | @subcommands]
    end
  end

  @doc """
  Creates a string flag with the given name, description and default value associated
  the currently defined program.
  """
  @spec string_flag(Flag.flag_name(), String.t(), Flag.flag_type()) :: Macro.t()
  defmacro string_flag(name, desc, default \\ nil) do
    quote do
      flag(unquote(name), :string, unquote(desc), unquote(default))
    end
  end

  @doc """
  Creates a integer flag with the given name, description and default value associated
  the currently defined program.
  """
  @spec int_flag(Flag.flag_name(), String.t(), Flag.flag_type()) :: Macro.t()
  defmacro int_flag(name, desc, default \\ nil) do
    quote do
      flag(unquote(name), :integer, unquote(desc), unquote(default))
    end
  end

  @doc """
  Creates a bool flag with the given name, description and default value associated
  the currently defined program.
  """
  @spec bool_flag(Flag.flag_name(), String.t(), Flag.flag_type()) :: Macro.t()
  defmacro bool_flag(name, desc, default \\ nil) do
    quote do
      flag(unquote(name), :boolean, unquote(desc), unquote(default))
    end
  end

  @doc """
  Creates a float flag with the given name, description and default value associated
  the currently defined program.
  """
  @spec float_flag(Flag.flag_name(), String.t(), Flag.flag_type()) :: Macro.t()
  defmacro float_flag(name, desc, default \\ nil) do
    quote do
      flag(unquote(name), :float, unquote(desc), unquote(default))
    end
  end

  @doc """
  Creates a flag of the given type, with the given name, description and default value
  (if provided) and associates it to the root program.
  """
  @spec flag(Flag.flag_name(), Flag.flag_kind(), String.t(), Flag.flag_type()) :: Macro.t()
  defmacro flag(name, type, desc, default \\ nil) do
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
               description: unquote(desc),
               default: unquote(default)
             })
    end
  end

  @doc false
  defmacro __before_compile__(_env) do
    quote do
      @doc """
      Return the definition of this command so that it can be documented via help pages or
      used for execution.
      """
      @spec command_spec() :: Draconic.Command.t()
      def command_spec do
        if @name == nil do
          raise UnnamedCommandError,
            message: "The command defined by #{__MODULE__} did not define a name."
        end

        %Command{
          module: __MODULE__,
          name: @name,
          description: @description,
          short_description: @short_description,
          flags: flags(),
          subcommands: subcommands()
        }
      end

      @doc "Return the name of the command."
      @spec name() :: String.t()
      def name, do: @name

      @doc "Return the long description of this command."
      @spec desc() :: String.t()
      def desc, do: @description

      @doc "Retun the short description of this command."
      @spec short_desc() :: String.t()
      def short_desc, do: @short_description

      @doc "Return the set of flags defined for this command."
      @spec flags() :: %{required(atom()) => Draconic.Flag.t()}
      def flags, do: @flags

      @doc "A listing of subcommands associated with this command."
      @spec subcommands() :: [Draconic.Command.t()]
      def subcommands do
        @subcommands
        |> Enum.map(fn mod -> {apply(mod, :name, []), apply(mod, :command_spec, [])} end)
        |> Enum.into(%{})
      end
    end
  end
end
