defmodule Draconic.Flag do
  alias __MODULE__

  defstruct name: nil, alias: nil, type: nil, description: "", default: nil

  @typedoc """
  A flag kind that is supported by `OptionParser`.
  """
  @type flag_kind() :: :boolean | :string | :integer | :float | :count

  @typedoc """
  A simple type used in the spec of `t()` to define that a type can be a kind or a list
  with a kind and the symbol :keep in it.
  """
  @type flag_type() :: flag_kind() | [flag_kind() | :keep]

  @typedoc """
  A structure to represent an application flag, which has a name, an optional
  alias (shorthand), a description, a type and an optional default.
  """
  @type t() :: %Flag{
    name: atom(), 
    alias: atom(), 
    description: String.t(), 
    type: flag_type(),
    default: term()
  }

  @typedoc """
  A 2-tuple of string values where the first value is the flag representation
  as you would expect users to pass them to them to the command line 
  application and the second value is simply the description.
  """
  @type string_parts() :: {String.t(), String.t()}

  @doc """
  Generates a tuple pair where the first value is the string flag names stylized as
  they will be expected by the CLI (--flag or -f for long and alias respectively) and
  the second item in the tuple is the description. This structure is chosen to ease
  formatting so you can determine how to join the two parts before rendering it, for
  example in a help renderer.

  ## Parameters

   - flag: The `%Draconic.Flag{}` struct to provide string parts for.

  ## Returns

  Returns a tuple, for a flag named 'name' with an alias 'n' and a description, "This
  is a name." you would expect to see {"--name, -n", "This is a name."}.

  ## Examples

      iex> Draconic.Flag.string_parts(%Draconic.Flag{name: "name", alias: "n", description: "This is the name."})
      {"--name, -n", "This is the name."}

      iex> Draconic.Flag.sring_parts(%Draconic.Flag{name: "verbose", description: "Display lots of information"})
      {"--verbose", "Display lots of information"}

  """
  @spec string_parts(t()) :: string_parts()
  def string_parts(%Flag{name: name, alias: flag_alias, description: desc}) do
    string_parts(name, flag_alias, desc)
  end

  @spec string_parts(atom(), atom(), String.t()) :: string_parts()
  defp string_parts(name, nil, desc) do
    {"--" <> to_string(name), desc}
  end

  @spec string_parts(atom(), atom(), String.t()) :: string_parts()
  defp string_parts(name, flag_alias, desc) do
    long = "--" <> to_string(name)
    short = "-" <> to_string(flag_alias)
    {long <> ", " <> short, desc}
  end

  @doc """
  Take a list of flags and produce a keyword list containing :strict and :aliases keys
  based on the flag data provided, this will be fed to `OptionParser.parse/2` to parse
  the provided input from the user.

  ## Parameters
  
   - flags: A list of `%Draconic.Flag{}` structs that will be used to generate the
     keyword list.

  ## Returns

  Returns a keyword list, containing :strict and :aliases.

  ## Examples
  
      iex> Draconic.Flag.flags_for_option_parser([%Draconic.Flag{name: :verbose, type: :boolean}, %Draconic.Flag{name: :input, alias: :i, type: :string}])
      [strict: [verbose: :boolean, input: :string], aliases: [i: :input]]

  """
  @spec to_options([t()]) :: keyword()
  def to_options(flags) do
    {switches, aliases} =
      flags
      |> Enum.map(&option_parser_parts/1)
      |> Enum.reduce({[], []}, &reduce_option_parser_data/2)
    [strict: Enum.reverse(switches), aliases: Enum.reverse(aliases)]
  end

  @spec reduce_option_parser_data({atom(), nil}, {keyword(), keyword()}) :: {keyword(), keyword()}
  defp reduce_option_parser_data({switch, nil}, {switches, aliases}) do
    {[switch | switches], aliases}
  end

  @spec reduce_option_parser_data({{atom(), flag_type()}, {atom(), atom()}}, {keyword(), keyword()}) :: {keyword(), keyword()}
  defp reduce_option_parser_data({switch, alias_data}, {switches, aliases}) do
    {[switch | switches], [alias_data | aliases]}
  end

  @spec option_parser_parts(t()) :: {{atom(), flag_type()}, nil}
  defp option_parser_parts(%Flag{name: name, alias: nil, type: type}) do
    {{name, type}, nil}
  end

  @spec option_parser_parts(t()) :: {{atom(), flag_type()}, {atom(), atom()}}
  defp option_parser_parts(%Flag{name: name, alias: flag_alias, type: type}) do
    {{name, type}, {flag_alias, name}}
  end
end
