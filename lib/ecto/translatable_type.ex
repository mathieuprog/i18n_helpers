defmodule I18nHelpers.Ecto.TranslatableType do
  use Ecto.Type

  # data type we want to use to store our custom value at the database level
  def type, do: :map

  # takes a value from an external source (for example a user input) and
  # converts it into a format that Ecto can work with
  def cast(translations) when translations == %{}, do: {:ok, nil}

  def cast(%{} = translations) do
    translations_without_empty =
      translations
      |> Enum.reject(fn {_, v} -> String.trim(v) == "" end)
      |> Map.new()
      |> (fn map when map == %{} -> nil; map -> map end).()

    {:ok, translations_without_empty}
  end
  def cast(nil), do: {:ok, nil}
  def cast(_), do: :error

  # converts the raw value pulled from the database into an Elixir value
  def load(term), do: Ecto.Type.load(:map, term)

  # takes an Elixir value and converts it into a value that the database recognizes
  def dump(term), do: Ecto.Type.dump(:map, term)
end
