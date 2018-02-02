defmodule Draconic.HelpRenderer do
  @callback render(Dragonic.Program.t(), Draconic.Program.flags(), Draconic.Program.args(), [
              String.t()
            ]) :: String.t()
end
