defmodule Draconic.ProgramTest do
  use ExUnit.Case

  alias Draconic.Command
  alias Draconic.Program
  alias Draconic.Flag

  defmodule SpanishCmd do
    use Command

    name "sp"

    def run(_flags, _args), do: nil
  end

  defmodule HelloCmd do
    use Command

    name "hello"
    string_flag :name, "a name", "World"
    subcommand SpanishCmd

    def run(_flags, _args), do: nil
  end

  defmodule TestProgram do
    use Program

    name "test"
    desc "a program description"
    bool_flag :verbose, "a boolean flag", false
    int_flag {:num, :n}, "an int flag", 0

    command HelloCmd
  end

  describe ".program_spec/0" do
    test "returns the expected values" do
      assert TestProgram.program_spec() == %Program{
               module: TestProgram,
               name: "test",
               description: "a program description",
               help_command: true,
               flags: %{
                 help: %Flag{
                   name: :help,
                   alias: :h,
                   type: :boolean,
                   description: "Print this page, providing useful information about the program.",
                   default: false
                 },
                 verbose: %Flag{
                   name: :verbose,
                   alias: nil,
                   type: :boolean,
                   description: "a boolean flag",
                   default: false
                 },
                 num: %Flag{
                   name: :num,
                   alias: :n,
                   type: :integer,
                   description: "an int flag",
                   default: 0
                 }
               },
               commands: %{
                 "hello" => %Command{
                   name: "hello",
                   module: HelloCmd,
                   description: "",
                   short_description: "",
                   flags: %{
                     name: %Flag{
                       name: :name,
                       alias: nil,
                       type: :string,
                       description: "a name",
                       default: "World"
                     }
                   },
                   subcommands: %{
                     "sp" => %Command{
                       name: "sp",
                       module: SpanishCmd,
                       description: "",
                       short_description: "",
                       flags: %{},
                       subcommands: %{}
                     }
                   }
                 }
               }
             }
    end
  end
end
