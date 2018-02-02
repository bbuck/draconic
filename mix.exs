defmodule Draconic.MixProject do
  use Mix.Project

  def project do
    [
      app: :draconic,
      version: "0.1.0",
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package()
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

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"},
    ]
  end
end
