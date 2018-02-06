defmodule Draconic.Command do
  alias __MODULE__
  alias Draconic.UnnamedCommandError
  alias Draconic.Flag

  @type status_code() :: integer() | nil

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

  defstruct module: nil,
            name: nil,
            description: "",
            short_description: "",
            flags: %{},
            subcommands: %{}

  # TODO: replace [String.t()] with argv() and define status_code() in Draconic.Program
  @callback run(Flag.flag_map(), [String.t()]) :: status_code()
  @callback command_spec() :: t()

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

  defmacro short_desc(short_desc) do
    quote do
      @short_description unquote(short_desc)
    end
  end

  defmacro subcommand(module) do
    quote do
      @subcommands [unquote(module) | @subcommands]
    end
  end

  defmacro string_flag(name, desc, default \\ nil) do
    quote do
      flag(unquote(name), :string, unquote(desc), unquote(default))
    end
  end

  defmacro int_flag(name, desc, default \\ nil) do
    quote do
      flag(unquote(name), :integer, unquote(desc), unquote(default))
    end
  end

  defmacro bool_flag(name, desc, default \\ nil) do
    quote do
      flag(unquote(name), :boolean, unquote(desc), unquote(default))
    end
  end

  defmacro float_flag(name, desc, default \\ nil) do
    quote do
      flag(unquote(name), :float, unquote(desc), unquote(default))
    end
  end

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

  defmacro __before_compile__(_env) do
    quote do
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

      def name, do: @name

      def desc, do: @description

      def short_desc, do: @short_description

      def flags, do: @flags

      def subcommands do
        @subcommands
        |> Enum.map(fn mod -> {apply(mod, :name, []), apply(mod, :command_spec, [])} end)
        |> Enum.into(%{})
      end
    end
  end
end
