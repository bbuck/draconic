# Draconic

[![docs](https://img.shields.io/badge/docs-hex.pm-blue.svg)](https://hexdocs.pm/draconic/api-reference.html) ![status active](https://img.shields.io/badge/status-active-green.svg)

Draconic is a DSL for building command line programs. It allows you to define your
CLI via simplistic macro functions that get compiled into simple modules used at 
run time to execute the desired command users enter. It's built on top of the
built in `OptionParser` so it's flag definitions are a remnant of those supported
by `OptionParser`. Although the goal was to unify aspects of an option flag as 
singular unit.

With Draconic commands are defined as their own modules, and as behaviors you 
just implement the run method that will be invoked if the command is given.
Associating these commands to a program is a simple call to a macro passing in the
module defining the command.

Commands in Draconic function like a tree, supporting nested (or "sub") commands
with their own set of flags. Flags are parsed from top to bottom, following the
path of commands, so global flags are parsed, the flags for the first command,
the second and down to the nth. So the lowest command executed (the only one the
`run` method will be called for) has access to all flags defined before it.

#### Examples

Define a program.

```elixir
defmodule CSVParser.CLI do
  use Draconic.Program

  alias CSVParser.CLI.Commands

  name "awesome"
  
  command Commands.Mapper
  command Commands.Lister
end
```

Configure your escipt program.

```elixir
defmodule CSVParser.MixProject do
  # ...
  def escript do
    [
      main_module: CSVParser.CLI
    ]
  end
  # ...
end
```

Then just execute your program!

```bash
csv_parser list --input example.csv
```


## Installation

Draconic can be installed from Hex by adding `draconic` to your list of 
dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:draconic, "~> 0.1.0"}
  ]
end
```
