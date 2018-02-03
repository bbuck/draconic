defmodule Draconic.FlagTest do
  use ExUnit.Case

  alias Draconic.Flag

  test "string parts with no alias" do
    flag = %Flag{name: "test", description: "This is a description"}
    assert Flag.string_parts(flag) == {"--test", "This is a description"}
  end

  test "string parts with alias" do
    flag = %Flag{name: :test, alias: :t, description: "This is a description"}
    assert Flag.string_parts(flag) == {"--test, -t", "This is a description"}
  end

  test "generates proper OptionParser options" do
    flags = [
      %Flag{name: :verbose, type: :boolean, alias: :v},
      %Flag{name: :input, type: :string}
    ]
    assert Flag.to_options(flags) == [strict: [verbose: :boolean, input: :string], aliases: [v: :verbose]]
  end
end
