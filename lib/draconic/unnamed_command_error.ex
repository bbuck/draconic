defmodule Draconic.UnnamedCommandError do
  defexception message: "Un-named command provided, all commands defined must have a name."
end
