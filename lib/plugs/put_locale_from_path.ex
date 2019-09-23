defmodule I18nHelpers.Plugs.PutLocaleFromPath do
  @moduledoc """
  Plug to fetch the locale from the first segment of the URL's request path;
  assigns the locale to the Connection and sets the Gettext locale.

  This plug is useful if you have URLs similar to:

      https://example.com/fr/bonjour
      https://example.com/nl/hallo
      https://example.com/es/hola
      https://example.com/hello (default locale "en")

  ## Options

    * `:default_locale` - locale to be used if no locale was found in the URL
    * `:allowed_locales` - a list of allowed locales. If no locale was found,
    use the `:default locale` if specified, otherwise raise an error.

  """

  alias I18nHelpers.Plugs.PutLocaleFromConn

  @spec init(keyword) :: keyword
  def init(options) do
    options =
      Keyword.put(options, :find_locale, fn conn ->
        List.first(conn.path_info)
      end)

    options =
      Keyword.put(options, :handle_missing_locale, fn conn ->
        raise "locale not found in path #{conn.request_path}"
      end)

    PutLocaleFromConn.init(options)
  end

  @spec call(Plug.Conn.t(), keyword) :: Plug.Conn.t()
  def call(conn, options) do
    PutLocaleFromConn.call(conn, options)
  end
end
