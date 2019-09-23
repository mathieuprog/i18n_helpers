defmodule I18nHelpers.Plugs.PutLocaleFromDomain do
  @moduledoc """
  Plug to fetch the locale from the URL's subdomain;
  assigns the locale to the Connection and sets the Gettext locale.

  This plug is useful if you have URLs similar to:

      https://mon-super-site.example/bonjour
      https://mijn-geweldige-website.example/hallo
      https://mi-gran-sitio.example/hola
      https://my-awesome-website.example/hello

  ## Options

    * `:domains_locales_map` - map where each key represents a domain and each
    value contains the locale to be used for that domain
    * `:default_locale` - locale to be used if no locale was found in the URL
    * `:allowed_locales` - a list of allowed locales. If no locale was found,
    use the `:default locale` if specified, otherwise raise an error.

  `:domains_locales_map` is a mandatory option. Below is an example of a map
  it can hold:

      %{
        "mon-super-site.example" => "fr",
        "mijn-geweldige-website.example" => "nl",
        "mi-gran-sitio.example" => "es",
        "my-awesome-website.example" => "en"
      }

  """

  alias I18nHelpers.Plugs.PutLocaleFromConn

  @spec init(keyword) :: keyword
  def init(options) do
    domains_locales_map =
      Keyword.get(options, :domains_locales_map) ||
        raise ArgumentError, "must supply `domains_locales_map` option"

    options =
      Keyword.put(options, :find_locale, fn conn ->
        Enum.find_value(domains_locales_map, fn {domain, locale} ->
          cond do
            String.contains?(conn.host, domain) -> locale
            true -> nil
          end
        end)
      end)

    options =
      Keyword.put(options, :handle_missing_locale, fn conn ->
        raise "locale not found in host #{conn.host}"
      end)

    PutLocaleFromConn.init(options)
  end

  @spec call(Plug.Conn.t(), keyword) :: Plug.Conn.t()
  def call(conn, options) do
    PutLocaleFromConn.call(conn, options)
  end
end
