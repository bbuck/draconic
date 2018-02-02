defmodule Draconic.Command do
  alias Draconic.UnnamedCommandError

  @type flags() :: keyword()
  @type args() :: [String.t()]
  @type command_spec() :: map()
  @type status_code() :: integer() | nil

  @callback run(flags(), args()) :: status_code()
  @callback command_spec() :: command_spec()

  defmacro __using__(_opts) do
    quote do
      import Draconic.Command

      @behaviour Draconic.Command

      @name nil
      @description ""
      @short_description ""
      @flags []
      @aliases []
      @subcommands []

      @before_compile Draconic.Command
    end
  end

  defmacro name(name) do
    quote do
      @name unquote(name)
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

  defmacro desc(description) do
    quote do
      @description unquote(description)
    end
  end

  defmacro short(short_desc) do
    quote do
      @short_description unquote(short_desc)
    end
  end

  defmacro subcommand(module) do
    quote do
      @subcommands [unquote(module) | @subcommands]
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      def command_spec do
        if @name == nil do
          raise UnnamedCommandError,
            message: "The command defined by #{__MODULE__} did not define a name."
        end

        %{
          module: __MODULE__,
          name: @name,
          description: @description,
          short: @short_description,
          flags: Enum.reverse(@flags),
          aliases: Enum.reverse(@aliases),
          subcommands: subcommands()
        }
      end

      def name, do: @name

      defp subcommands do
        @subcommands
        |> Enum.map(fn mod -> {apply(mod, :name, []), apply(mod, :command_spec, [])} end)
        |> Enum.into(%{})
      end
    end
  end
end
