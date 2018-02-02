defmodule Draconic.CommandTest do
  use ExUnit.Case

  defmodule TestCommand do
    use Draconic.Command

    name("test")
    desc("This is a test command")
    short("This is a short desc")
    flag(:name, :boolean)
    alias_flag(:n, :name)
    flag(:other, :string)

    def run(_flags, _args), do: nil
  end

  defmodule EmptyCommand do
    use Draconic.Command

    def run(_flags, _args), do: nil
  end

  defmodule DefaultCommand do
    use Draconic.Command

    name("root")

    def run(_flags, _args), do: nil
  end

  defmodule SubcommandCommand do
    use Draconic.Command

    name("subcommand_test")
    subcommand(TestCommand)

    def run(_flags, _args), do: nil
  end

  test "command_spec returns the expected value" do
    assert TestCommand.command_spec() == %{
             module: TestCommand,
             name: "test",
             description: "This is a test command",
             short: "This is a short desc",
             flags: [name: :boolean, other: :string],
             subcommands: %{},
             aliases: [n: :name]
           }
  end

  test "commands without a name raise an error" do
    assert_raise Draconic.UnnamedCommandError, fn ->
      EmptyCommand.command_spec()
    end
  end

  test "defaults are applied if nothing is specified" do
    assert DefaultCommand.command_spec() == %{
             module: DefaultCommand,
             name: "root",
             description: "",
             short: "",
             flags: [],
             subcommands: %{},
             aliases: []
           }
  end

  test "subcommands call command spec as expected" do
    assert SubcommandCommand.command_spec() == %{
             module: SubcommandCommand,
             name: "subcommand_test",
             description: "",
             short: "",
             flags: [],
             aliases: [],
             subcommands: %{
               "test" => %{
                 module: TestCommand,
                 name: "test",
                 description: "This is a test command",
                 short: "This is a short desc",
                 flags: [name: :boolean, other: :string],
                 subcommands: %{},
                 aliases: [n: :name]
               }
             }
           }
  end
end
