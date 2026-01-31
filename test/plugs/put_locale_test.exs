defmodule I18nHelpers.Plugs.PutLocaleTest do
  use ExUnit.Case, async: true

  import Plug.Test

  alias I18nHelpers.Plugs.PutLocale

  doctest PutLocale

  test "init PutLocale plug" do
    assert_raise ArgumentError, ~r"must supply `find_locale` option", fn ->
      PutLocale.init([])
    end
  end

  defp find_locale(conn) do
    case conn.host do
      "en.example.com" ->
        "en"

      "nl.example.com" ->
        "nl"

      _ ->
        case conn.path_info do
          ["en" | _] -> "en"
          ["nl" | _] -> "nl"
          _ -> "en"
        end
    end
  end

  test "find_locale/1 custom function" do
    options = PutLocale.init(find_locale: &find_locale/1)

    conn = conn(:get, "/hello")
    conn = PutLocale.call(conn, options)

    assert conn.assigns == %{locale: "en"}

    conn = conn(:get, "/nl/hallo")
    conn = PutLocale.call(conn, options)

    assert conn.assigns == %{locale: "nl"}

    conn = conn(:get, "https://en.example.com/hello")
    conn = PutLocale.call(conn, options)

    assert conn.assigns == %{locale: "en"}

    conn = conn(:get, "https://nl.example.com/hallo")
    conn = PutLocale.call(conn, options)

    assert conn.assigns == %{locale: "nl"}
  end
end
