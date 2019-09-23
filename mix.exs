defmodule I18nHelpers.MixProject do
  use Mix.Project

  def project do
    [
      app: :i18n_helpers,
      version: "0.5.0",
      elixir: "~> 1.9",
      deps: deps(),
      elixirc_paths: elixirc_paths(Mix.env())
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:plug, "~> 1.8.3 or ~> 1.9", optional: true},
      {:ecto, "~> 3.2", optional: true},
      {:gettext, "~> 0.17"},
      {:ex_doc, "~> 0.21", only: :dev},
      {:inch_ex, "~> 2.0", only: :dev},
      {:dialyxir, "~> 0.5", only: :dev}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]
end
