defmodule I18nHelpers.Plugs.PutLocaleFromConn do
  @moduledoc false

  import Plug.Conn

  @spec init(keyword) :: keyword
  def init(options) do
    allowed_locales = Keyword.get(options, :allowed_locales)
    default_locale = Keyword.get(options, :default_locale)

    cond do
      allowed_locales == nil ->
        options

      default_locale == nil ->
        options

      true ->
        Enum.member?(allowed_locales, default_locale) ||
          raise ArgumentError, "`default_locale` is not included in `allowed_locales` option"

        options
    end
  end

  @spec get_allowed_locale_or_default(String.t() | nil, list | nil, String.t() | nil) ::
          String.t() | nil
  defp get_allowed_locale_or_default(nil, _allowed_locales, default_locale), do: default_locale

  defp get_allowed_locale_or_default(locale, nil, default_locale) do
    cond do
      byte_size(locale) == 2 -> locale
      String.match?(locale, ~r/[\w]{2}[-_][\w]{2}/) -> locale
      true -> default_locale
    end
  end

  defp get_allowed_locale_or_default(locale, allowed_locales, default_locale) do
    cond do
      Enum.member?(allowed_locales, locale) -> locale
      true -> default_locale
    end
  end

  @spec call(Plug.Conn.t(), keyword) :: Plug.Conn.t()
  def call(conn, options) do
    find_locale = Keyword.fetch!(options, :find_locale)
    handle_missing_locale = Keyword.fetch!(options, :handle_missing_locale)
    allowed_locales = Keyword.get(options, :allowed_locales)
    default_locale = Keyword.get(options, :default_locale)
    backend = Keyword.get(options, :backend)

    locale =
      get_allowed_locale_or_default(find_locale.(conn), allowed_locales, default_locale) ||
        handle_missing_locale.(conn)

    if backend,
      do: Gettext.put_locale(backend, locale),
      else: Gettext.put_locale(locale)

    assign(conn, :locale, locale)
  end
end
