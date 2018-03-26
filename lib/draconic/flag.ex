defmodule Draconic.Flag do
  alias __MODULE__

  defstruct name: nil, alias: nil, type: nil, description: "", default: nil

  @typedoc "The name of the flag, `--verbose` would have the name `:verbose`"
  @type name() :: atom()

  @typedoc "A flags alias, if `-v` maps to `--verbose` then it's alias is `:v`."
  @type alias() :: atom()

  @typedoc """
  Poorly named wrapper for the potential names of a flag (used outside this module).
  A flag name can either be a name (atom) or a tuple of a name and alias (both atoms).
  So `:verbose` is valid and `{:verbose, :v}` as well.
  """
  @type flag_name() :: name() | {name(), alias()}

  @typedoc """
  A flag kind that is supported by `OptionParser`.
  """
  @type flag_kind() :: :boolean | :string | :integer | :float | :count

  @typedoc """
  Represents the type of the _data_ associated to a flag. For example a flag like
  `:num` may have a `flag_kind()` of `:integer`, but it's actual value (given by
  the user) may be `10` (in the case of `--num 10`).
  """
  @type flag_value_kind() :: boolean() | String.t() | integer() | float() | nil

  @typedoc """
  A simple type used in the spec of `t()` to define that a type can be a kind or a list
  with a kind and the symbol :keep in it.
  """
  @type flag_type() :: flag_kind() | [flag_kind() | :keep]

  @typedoc """
  Similar to the difference between `flag_kind()` and `flag_value_kind()` where this type
  is referring to the value provided by the user (or the default value of the flag).
  """
  @type flag_value_type() :: flag_value_kind() | [flag_value_kind()]

  @typedoc """
  A structure to represent an application flag, which has a name, an optional
  alias (shorthand), a description, a type and an optional default.
  """
  @type t() :: %Flag{
          name: name(),
          alias: alias(),
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

  @typedoc """
  A map that maps a name (should be an atom) to a `%Draconic.Flag{}` struct defining
  the flag. This flag definition is used when building a map from a set of flags
  provided by the user when invoking the application.
  """
  @type flag_definition() :: %{required(name()) => t()}

  @typedoc """
  A map mapping a flag name (should be an atom) to a value that represents the information
  the user provided for that flag (or it's default value). All defined flags should appear
  in a flag map, regardless of whether it was explicitly passed.
  """
  @type flag_map() :: %{name() => flag_value_type()}

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
  def string_parts(%Flag{name: name, type: type, alias: flag_alias, description: desc}) do
    string_parts(name, flag_alias, desc, type)
  end

  @spec string_parts(name(), nil, String.t(), :boolean) :: string_parts()
  defp string_parts(name, nil, desc, :boolean) do
    {"--[no-]" <> to_string(name), desc}
  end

  @spec string_parts(name(), alias(), String.t(), flag_type()) :: string_parts()
  defp string_parts(name, nil, desc, _type) do
    {"--" <> to_string(name), desc}
  end

  @spec string_parts(name(), alias(), String.t(), :boolean) :: string_parts()
  defp string_parts(name, flag_alias, desc, :boolean) do
    long = "--[no-]" <> to_string(name)
    short = "-" <> to_string(flag_alias)
    {long <> ", " <> short, desc}
  end

  @spec string_parts(name(), alias(), String.t(), flag_type()) :: string_parts()
  defp string_parts(name, flag_alias, desc, _type) do
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

      iex> Draconic.Flag.to_options([%Draconic.Flag{name: :verbose, type: :boolean}, %Draconic.Flag{name: :input, alias: :i, type: :string}])
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

  @spec reduce_option_parser_data({name(), nil}, {keyword(), keyword()}) :: {keyword(), keyword()}
  defp reduce_option_parser_data({switch, nil}, {switches, aliases}) do
    {[switch | switches], aliases}
  end

  @spec reduce_option_parser_data(
          {{name(), flag_type()}, {name(), alias()}},
          {keyword(), keyword()}
        ) :: {keyword(), keyword()}
  defp reduce_option_parser_data({switch, alias_data}, {switches, aliases}) do
    {[switch | switches], [alias_data | aliases]}
  end

  @spec option_parser_parts(t()) :: {{name(), flag_type()}, nil}
  defp option_parser_parts(%Flag{name: name, alias: nil, type: type}) do
    {{name, type}, nil}
  end

  @spec option_parser_parts(t()) :: {{name(), flag_type()}, {name(), alias()}}
  defp option_parser_parts(%Flag{name: name, alias: flag_alias, type: type}) do
    {{name, type}, {flag_alias, name}}
  end

  @doc """
  """
  @spec to_map(flag_definition(), keyword()) :: flag_map()
  def to_map(flag_definitions, passed_flags) do
    built_map =
      passed_flags
      |> Enum.reduce(%{}, &insert_into_flag_map/2)
      |> Enum.map(&reverse_flag_value_lists/1)
      |> Enum.into(%{})

    flag_definitions
    |> Enum.map(find_missing_flags_from(built_map))
    |> Enum.filter(fn x -> x != nil end)
    |> Enum.into(built_map)
  end

  @spec insert_into_flag_map({name(), flag_value_type()}, flag_map()) :: flag_map()
  defp insert_into_flag_map({flag_key, flag_val}, flag_map) do
    case Map.fetch(flag_map, flag_key) do
      {:ok, value_list} when is_list(value_list) ->
        Map.put(flag_map, flag_key, [flag_val | value_list])

      {:ok, value} ->
        Map.put(flag_map, flag_key, [flag_val, value])

      :error ->
        Map.put(flag_map, flag_key, flag_val)
    end
  end

  @spec find_missing_flags_from(flag_map()) ::
          ({name(), t()} -> nil | {name(), flag_value_type()})
  defp find_missing_flags_from(map) do
    fn {key, flag_def} ->
      case Map.fetch(map, key) do
        {:ok, _} -> nil
        :error -> {key, flag_def.default}
      end
    end
  end

  @spec reverse_flag_value_lists({name(), flag_value_type()}) :: {name(), flag_value_type()}
  defp reverse_flag_value_lists({key, value}) when is_list(value), do: {key, Enum.reverse(value)}

  @spec reverse_flag_value_lists({name(), flag_value_type()}) :: {name(), flag_value_type()}
  defp reverse_flag_value_lists(entry), do: entry
end
