defmodule Draconic.Command do
  alias __MODULE__
  alias Draconic.UnnamedCommandError

  @type t() :: %Command{}

  #@callback run(flags(), args()) :: status_code()
  #@callback command_spec() :: command_spec()

  defstruct module: nil, name: nil, description: "", short: "", flags: %{}, subcommands: %{}

  defmacro __using__(_opts) do
    quote do
      import Draconic.Command

      @behaviour Draconic.Command

      @name nil
      @description ""
      @short_description ""
      @flags []
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

        %Command{
          module: __MODULE__,
          name: @name,
          description: @description,
          short: @short_description,
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
