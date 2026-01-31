defmodule I18nHelpers.Plugs.PutLocaleFromDomainTest do
  use ExUnit.Case, async: true

  import Plug.Test

  alias I18nHelpers.Plugs.PutLocaleFromDomain

  doctest PutLocaleFromDomain

  test "init PutLocaleFromDomain plug" do
    assert_raise ArgumentError,
                 ~r"must supply `domains_locales_map` option",
                 fn ->
                   PutLocaleFromDomain.init([])
                 end

    assert_raise ArgumentError,
                 ~r"`default_locale` is not included in `allowed_locales` option",
                 fn ->
                   PutLocaleFromDomain.init(
                     domains_locales_map: %{
                       "english.example" => "en",
                       "nederlands.example" => "nl"
                     },
                     allowed_locales: ["nl"],
                     default_locale: "en"
                   )
                 end
  end

  test "PutLocaleFromDomain plug with only domains_locales_map option" do
    options =
      PutLocaleFromDomain.init(
        domains_locales_map: %{
          "english.example" => "en",
          "nederlands.example" => :nl
        }
      )

    conn = conn(:get, "https://example.com/hello")

    assert_raise RuntimeError, ~r"locale not found in host example.com", fn ->
      PutLocaleFromDomain.call(conn, options)
    end

    conn = conn(:get, "https://english.example/hello")
    conn = PutLocaleFromDomain.call(conn, options)

    assert conn.assigns == %{locale: "en"}

    conn = conn(:get, "https://nederlands.example/hallo")
    conn = PutLocaleFromDomain.call(conn, options)

    assert conn.assigns == %{locale: "nl"}

    conn = conn(:get, "https://foo.nederlands.example/hallo")
    conn = PutLocaleFromDomain.call(conn, options)

    assert conn.assigns == %{locale: "nl"}
  end

  test "PutLocaleFromDomain plug options" do
    base_options = [
      domains_locales_map: %{
        "english.example" => "en",
        "nederlands.example" => "nl"
      }
    ]

    options = PutLocaleFromDomain.init(Keyword.put(base_options, :default_locale, "en"))

    conn = conn(:get, "https://example.com/hello")
    conn = PutLocaleFromDomain.call(conn, options)

    assert conn.assigns == %{locale: "en"}

    options = PutLocaleFromDomain.init(Keyword.put(base_options, :allowed_locales, ["en", "nl"]))

    conn = conn(:get, "https://english.example/hello")
    conn = PutLocaleFromDomain.call(conn, options)

    assert conn.assigns == %{locale: "en"}

    conn = conn(:get, "https://example.com/hello")

    assert_raise RuntimeError, ~r"locale not found in host example.com", fn ->
      PutLocaleFromDomain.call(conn, options)
    end

    options =
      Keyword.put(base_options, :allowed_locales, ["en", "nl"])
      |> Keyword.put(:default_locale, "en")

    options = PutLocaleFromDomain.init(options)

    conn = conn(:get, "https://example.com/hello")
    conn = PutLocaleFromDomain.call(conn, options)

    assert conn.assigns == %{locale: "en"}

    conn = conn(:get, "https://nederlands.example/hallo")
    conn = PutLocaleFromDomain.call(conn, options)

    assert conn.assigns == %{locale: "nl"}
  end
end
