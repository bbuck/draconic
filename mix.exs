defmodule Draconic.MixProject do
  use Mix.Project

  def project do
    [
      app: :draconic,
      version: "0.1.1",
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),
      docs: docs()
    ]
  end

  def package() do
    [
      description: "Draconic provides a DSL for easily building complex command line interfaces.",
      licenses: ["MIT"],
      maintainers: ["Brandon Buck"],
      links: %{
        github: "https://github.com/bbuck/draconic"
      },
      source_url: "https://github.com/bbuck/draconic"
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:ex_doc, ">= 0.0.0", env: :dev}
    ]
  end

  defp docs() do
    [
      extras: ["README.md" | Path.wildcard("pages/*.md")]
    ]
  end
end
