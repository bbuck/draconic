defmodule Draconic.CommandTest do
  use ExUnit.Case

  alias Draconic.Command
  alias Draconic.Flag

  defmodule TestCommand do
    use Draconic.Command

    name "test"
    desc "This is a test command"
    short_desc "This is a short desc"
    bool_flag {:name, :n}, "a boolean flag"
    string_flag :other, "a string flag", "default"

    def run(_flags, _args), do: nil
  end

  defmodule EmptyCommand do
    use Draconic.Command

    def run(_flags, _args), do: nil
  end

  defmodule DefaultCommand do
    use Draconic.Command

    name "root"

    def run(_flags, _args), do: nil
  end

  defmodule SubcommandCommand do
    use Draconic.Command

    name "subcommand_test"
    subcommand TestCommand

    def run(_flags, _args), do: nil
  end

  describe ".command_spec/0" do
    test "returns the expected value" do
      assert TestCommand.command_spec() == %Command{
               module: TestCommand,
               name: "test",
               description: "This is a test command",
               short_description: "This is a short desc",
               flags: %{
                 name: %Flag{
                   name: :name,
                   alias: :n,
                   type: :boolean,
                   description: "a boolean flag",
                   default: nil
                 },
                 other: %Flag{
                   name: :other,
                   alias: nil,
                   type: :string,
                   description: "a string flag",
                   default: "default"
                 }
               },
               subcommands: %{}
             }
    end

    test "commands without a name raise an error" do
      assert_raise Draconic.UnnamedCommandError, fn ->
        EmptyCommand.command_spec()
      end
    end

    test "defaults are applied if nothing is specified" do
      assert DefaultCommand.command_spec() == %Command{
               module: DefaultCommand,
               name: "root",
               description: "",
               short_description: "",
               flags: %{},
               subcommands: %{}
             }
    end

    test "subcommands call command_spec as expected" do
      assert SubcommandCommand.command_spec() == %Command{
               module: SubcommandCommand,
               name: "subcommand_test",
               description: "",
               short_description: "",
               flags: %{},
               subcommands: %{
                 "test" => %Command{
                   module: TestCommand,
                   name: "test",
                   description: "This is a test command",
                   short_description: "This is a short desc",
                   flags: %{
                     name: %Flag{
                       name: :name,
                       alias: :n,
                       type: :boolean,
                       description: "a boolean flag",
                       default: nil
                     },
                     other: %Flag{
                       name: :other,
                       alias: nil,
                       type: :string,
                       description: "a string flag",
                       default: "default"
                     }
                   },
                   subcommands: %{}
                 }
               }
             }
    end
  end
end
