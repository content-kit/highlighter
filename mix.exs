defmodule Highlighter.MixProject do
  use Mix.Project

  @version "0.1.0"
  @source_url "https://github.com/content-kit/highlighter"

  def project do
    [
      app: :highlighter,
      version: @version,
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      package: package(),
      description: description(),
      deps: deps()
    ]
  end

  defp deps do
    []
  end

  defp description() do
    """
    Highlight or annotate text using a list of annotations.
    """
  end

  defp package() do
    [
      maintainers: ["James Elligett"],
      files: ~w(lib mix.exs README* CHANGELOG*),
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => @source_url, "Changelog" => "#{@source_url}/blob/main/CHANGELOG.md"}
    ]
  end
end
