defmodule Draconic.Program do
  alias __MODULE__
  alias Draconic.Command
  alias Draconic.Flag

  @type t() :: %Program{
          module: module(),
          name: String.t(),
          description: String.t(),
          commands: [Command.t()],
          flags: Flag.flag_definition(),
          help_renderer: module(),
          help_command: true
        }

  defstruct module: nil,
            name: "",
            commands: [],
            description: "",
            flags: %{},
            default_command: "help",
            help_renderer: Draconic.BasicHelp,
            help_command: true

  defmacro __using__(_) do
    quote do
      import Draconic.Program

      @name "PROGRAM"
      @commands []
      @description ""
      @flags %{}
      @help_renderer Draconic.BasicHelp
      @help_flag_name {:help, :h}
      @help_command true
      @default_command "help"

      @before_compile Draconic.Program
    end
  end

  defmacro name(name) do
    quote do
      @name unquote(name)
    end
  end

  defmacro desc(description) do
    quote do
      @description unquote(description)
    end
  end

  defmacro default_command(cmd) do
    quote do
      @default_command unquote(cmd)
    end
  end

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

  defmacro int_flag(name, description, default \\ nil) do
    quote do
      flag(unquote(name), :integer, unquote(description), unquote(default))
    end
  end

  defmacro float_flag(name, description, default \\ nil) do
    quote do
      flag(unquote(name), :float, unquote(description), unquote(default))
    end
  end

  defmacro bool_flag(name, description, default \\ nil) do
    quote do
      flag(unquote(name), :boolean, unquote(description), unquote(default))
    end
  end

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

  defmacro help_renderer(mod) do
    quote do
      @help_renderer unquote(mod)
    end
  end

  defmacro help_flag(name) do
    quote do
      @help_flag_name unquote(name)
    end
  end

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

      def help_command(), do: @help_command

      def program_spec do
        %Program{
          name: @name,
          description: @description,
          module: __MODULE__,
          commands: commands(),
          flags: flags(),
          default_command: default_command(),
          help_renderer: help_renderer(),
          help_command: help_command()
        }
      end

      def main(args) do
        Draconic.Executor.execute(program_spec(), args)
      end
    end
  end
end
