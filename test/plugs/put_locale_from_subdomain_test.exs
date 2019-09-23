defmodule I18nHelpers.Plugs.PutLocaleFromSubdomainTest do
  use ExUnit.Case, async: true

  use Plug.Test

  alias I18nHelpers.Plugs.PutLocaleFromSubdomain

  doctest PutLocaleFromSubdomain

  test "init PutLocaleFromSubdomain plug" do
    assert_raise ArgumentError,
                 ~r"`default_locale` is not included in `allowed_locales` option",
                 fn ->
                   PutLocaleFromSubdomain.init(
                     allowed_locales: ["fr", "nl"],
                     default_locale: "en"
                   )
                 end
  end

  test "PutLocaleFromSubdomain plug without options" do
    options = PutLocaleFromSubdomain.init([])

    conn = conn(:get, "https://example.com/hello")

    assert_raise RuntimeError, ~r"locale not found in host example.com", fn ->
      PutLocaleFromSubdomain.call(conn, options)
    end

    conn = conn(:get, "https://fr.example.com/hello")
    conn = PutLocaleFromSubdomain.call(conn, options)

    assert conn.assigns == %{locale: "fr"}
  end

  test "PutLocaleFromSubdomain plug options" do
    options = PutLocaleFromSubdomain.init(default_locale: "en")

    conn = conn(:get, "https://example.com/hello")
    conn = PutLocaleFromSubdomain.call(conn, options)

    assert conn.assigns == %{locale: "en"}

    options = PutLocaleFromSubdomain.init(allowed_locales: ["en", "fr"])

    conn = conn(:get, "https://en.example.com/hello")
    conn = PutLocaleFromSubdomain.call(conn, options)

    assert conn.assigns == %{locale: "en"}

    conn = conn(:get, "https://example.com/hello")

    assert_raise RuntimeError, ~r"locale not found in host example.com", fn ->
      PutLocaleFromSubdomain.call(conn, options)
    end

    conn = conn(:get, "https://nl.example.com/hallo")

    assert_raise RuntimeError, ~r"locale not found in host nl.example.com", fn ->
      PutLocaleFromSubdomain.call(conn, options)
    end

    options = PutLocaleFromSubdomain.init(allowed_locales: ["en", "fr"], default_locale: "en")

    conn = conn(:get, "https://example.com/hello")
    conn = PutLocaleFromSubdomain.call(conn, options)

    assert conn.assigns == %{locale: "en"}

    conn = conn(:get, "https://fr.example.com/bonjour")
    conn = PutLocaleFromSubdomain.call(conn, options)

    assert conn.assigns == %{locale: "fr"}

    conn = conn(:get, "https://nl.example.com/hallo")
    conn = PutLocaleFromSubdomain.call(conn, options)

    assert conn.assigns == %{locale: "en"}
  end
end
