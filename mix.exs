defmodule Goodoo.MixProject do
  use Mix.Project

  @version "0.1.0"

  def project() do
    [
      app: :goodoo,
      version: @version,
      elixir: "~> 1.6",
      deps: deps(),
      description: description(),
      package: package(),
      name: "Goodoo",
      docs: docs()
    ]
  end

  def application(), do: []

  defp description() do
    "A simple, robust, and highly customizable health check solution written in Elixir"
  end

  defp package() do
    [
      maintainers: ["Fishbrain"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/fishbrain/goodoo"}
    ]
  end

  defp deps() do
    [
      {:ecto_sql, "~> 3.0", optional: true},
      {:redix, "~> 1.0", optional: true},
      {:ex_doc, "~> 0.24", only: :dev, runtime: false}
    ]
  end

  defp docs() do
    [
      main: "Goodoo",
      source_ref: "v#{@version}",
      source_url: "https://github.com/fishbrain/goodoo"
    ]
  end
end
