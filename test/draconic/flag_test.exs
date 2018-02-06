defmodule Draconic.FlagTest do
  use ExUnit.Case

  alias Draconic.Flag

  describe ".string_parts/1" do
    test "string parts with no alias" do
      flag = %Flag{name: "test", description: "This is a description"}
      assert Flag.string_parts(flag) == {"--test", "This is a description"}
    end

    test "string parts with alias" do
      flag = %Flag{name: :test, alias: :t, description: "This is a description"}
      assert Flag.string_parts(flag) == {"--test, -t", "This is a description"}
    end

    test "handles boolean types specially" do
      flag = %Flag{name: :verbose, alias: :v, type: :boolean, description: "Boolean flag."}
      assert Flag.string_parts(flag) == {"--[no-]verbose, -v", "Boolean flag."}
    end

    test "handles boolean types specially even without an alias" do
      flag = %Flag{name: :verbose, type: :boolean, description: "Boolean flag."}
      assert Flag.string_parts(flag) == {"--[no-]verbose", "Boolean flag."}
    end
  end

  describe ".to_options/1" do
    test "generates proper OptionParser options" do
      flags = [
        %Flag{name: :verbose, type: :boolean, alias: :v},
        %Flag{name: :input, type: :string}
      ]

      assert Flag.to_options(flags) == [
               strict: [verbose: :boolean, input: :string],
               aliases: [v: :verbose]
             ]
    end
  end

  describe ".to_map/2" do
    setup do
      flag_defs = %{
        verbose: %Flag{
          name: :verbose,
          type: :boolean,
          alias: :v,
          description: "A verbose flag",
          default: false
        },
        name: %Flag{
          name: :name,
          type: :string,
          alias: :n,
          description: "Your name"
        },
        num: %Flag{
          name: :num,
          description: "A number",
          type: :integer,
          default: 0
        }
      }

      {:ok, flag_defs: flag_defs}
    end

    test "generates the proper map", %{flag_defs: flag_defs} do
      assert Flag.to_map(flag_defs, verbose: true, name: "Peter", num: 10) == %{
               verbose: true,
               name: "Peter",
               num: 10
             }
    end

    test "handles filling in default values", %{flag_defs: flag_defs} do
      assert Flag.to_map(flag_defs, []) == %{
               verbose: false,
               name: nil,
               num: 0
             }
    end

    test "handles multiple values for a flag", %{flag_defs: flag_defs} do
      assert Flag.to_map(flag_defs, num: 10, num: 15) == %{
               verbose: false,
               name: nil,
               num: [10, 15]
             }
    end
  end
end
