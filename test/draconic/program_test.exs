defmodule Draconic.ProgramTest do
  use ExUnit.Case

  defmodule SpanishCmd do
    use Draconic.Command

    name("sp")

    def run(_flags, _args) do
      101
    end
  end

  defmodule HelloCmd do
    use Draconic.Command

    name("hello")
    flag(:name, :string)
    subcommand(SpanishCmd)

    def run(_flags, _args) do
      202
    end
  end

  defmodule TestProgram do
    use Draconic.Program

    flag(:verbose, :boolean)

    command(HelloCmd)
  end

  test "executes the appropriate command" do
    assert TestProgram.run(["hello", "--name", "Brandon"]) == 202
  end

  test "executes the appropriate subcommand" do
    assert TestProgram.run(["hello", "--name", "Brandon", "sp"]) == 101
  end
end
