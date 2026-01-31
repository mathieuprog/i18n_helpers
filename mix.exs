defmodule I18nHelpers.MixProject do
  use Mix.Project

  @version "0.15.0"

  def project do
    [
      app: :i18n_helpers,
      elixir: "~> 1.9",
      deps: deps(),
      elixirc_paths: elixirc_paths(Mix.env()),

      # Hex
      version: @version,
      package: package(),
      description: "A set of tools to help you translate your Elixir applications",

      # ExDoc
      name: "I18n Helpers",
      source_url: "https://github.com/mathieuprog/i18n_helpers",
      docs: docs()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:gettext, "~> 1.0"},
      {:phoenix_html_helpers, "~> 1.0"},
      {:ecto, "~> 3.13", optional: true},
      {:phoenix_html, "~> 4.3", optional: true},
      {:plug, "~> 1.19", optional: true},
      {:ex_doc, "~> 0.40", only: :dev},
      {:inch_ex, "~> 2.1", only: :dev},
      {:dialyxir, "~> 1.4", only: :dev}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp package do
    [
      licenses: ["Apache 2.0"],
      maintainers: ["Mathieu Decaffmeyer"],
      links: %{"GitHub" => "https://github.com/mathieuprog/i18n_helpers"}
    ]
  end

  defp docs do
    [
      main: "readme",
      extras: ["README.md"],
      source_ref: "v#{@version}"
    ]
  end
end
