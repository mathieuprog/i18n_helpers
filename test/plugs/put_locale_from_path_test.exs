defmodule I18nHelpers.Plugs.PutLocaleFromPathTest do
  use ExUnit.Case, async: true

  import Plug.Test

  alias I18nHelpers.Plugs.PutLocaleFromPath

  doctest PutLocaleFromPath

  test "init PutLocaleFromPath plug" do
    assert_raise ArgumentError,
                 ~r"`default_locale` is not included in `allowed_locales` option",
                 fn ->
                   PutLocaleFromPath.init(allowed_locales: ["fr", "nl"], default_locale: "en")
                 end
  end

  test "PutLocaleFromPath plug without options" do
    options = PutLocaleFromPath.init([])

    conn = conn(:get, "/hello")

    assert_raise RuntimeError, ~r"locale not found in path /hello", fn ->
      PutLocaleFromPath.call(conn, options)
    end

    conn = conn(:get, "/fr/bonjour")
    conn = PutLocaleFromPath.call(conn, options)

    assert conn.assigns == %{locale: "fr"}
    assert Gettext.get_locale() == "fr"

    conn = conn(:get, "/fr-BE/bonjour")
    conn = PutLocaleFromPath.call(conn, options)

    assert conn.assigns == %{locale: "fr-BE"}
  end

  test "PutLocaleFromPath plug options" do
    options = PutLocaleFromPath.init(default_locale: "en")

    conn = conn(:get, "/hello")
    conn = PutLocaleFromPath.call(conn, options)

    assert conn.assigns == %{locale: "en"}

    options = PutLocaleFromPath.init(allowed_locales: [:en, "fr"])

    conn = conn(:get, "/en/hello")
    conn = PutLocaleFromPath.call(conn, options)

    assert conn.assigns == %{locale: "en"}

    conn = conn(:get, "/hello")

    assert_raise RuntimeError, ~r"locale not found in path /hello", fn ->
      PutLocaleFromPath.call(conn, options)
    end

    conn = conn(:get, "/nl/hallo")

    assert_raise RuntimeError, ~r"locale not found in path /nl/hallo", fn ->
      PutLocaleFromPath.call(conn, options)
    end

    options = PutLocaleFromPath.init(allowed_locales: ["en", "fr"], default_locale: "en")

    conn = conn(:get, "/hello")
    conn = PutLocaleFromPath.call(conn, options)

    assert conn.assigns == %{locale: "en"}

    conn = conn(:get, "/fr/bonjour")
    conn = PutLocaleFromPath.call(conn, options)

    assert conn.assigns == %{locale: "fr"}

    conn = conn(:get, "/nl/hallo")
    conn = PutLocaleFromPath.call(conn, options)

    assert conn.assigns == %{locale: "en"}
  end
end
