defmodule I18nHelpers.HTML.InputHelpers do
  @moduledoc ~S"""
  Provides view helpers to render HTML input fields for text that must be
  provided in multiple languages. The multilingual texts passed to the
  form (usually in a changeset) are expected to be maps where each key
  represents a locale and each value contains the text for that locale.
  For example:

      %{
        "en" => "hello world",
        "fr" => "bonjour monde",
        "nl" => "hallo wereld"
      }
  """

  alias Phoenix.HTML.Form

  @doc ~S"""
  Renders a text input HTML element filled with the translated value for the
  given locale.

  Additional HTML attributes can be provided through opts argument.
  """
  def translated_text_input(form, field, locale, opts \\ []) do
    opts = Keyword.put_new(opts, :name, translated_input_name(form, field, locale))

    translated_field(form, field, {:input, [type: "text"]}, locale, opts)
  end

  @doc ~S"""
  Renders a textarea input HTML element filled with the translated value for the
  given locale.

  Additional HTML attributes can be provided through opts argument.
  """
  def translated_textarea(form, field, locale, opts \\ []) do
    opts = Keyword.put_new(opts, :name, translated_input_name(form, field, locale))

    translated_field(form, field, {:textarea, []}, locale, opts)
  end

  @doc ~S"""
  Renders a custom input HTML element filled with the translated value for the
  given locale. The default element is `div` and may be changed through the `tag`
  option.

  Additional HTML attributes can be provided through opts argument.
  """
  def translated_element(form, field, locale, opts \\ []) do
    {tag, opts} = Keyword.pop(opts, :tag, :div)

    translated_field(form, field, {tag, []}, locale, opts)
  end

  defp translated_field(form, field, {tag, attrs}, locale, opts) do
    locale = to_string(locale)

    translations = Form.input_value(form, field) || %{}
    translation = Map.get(translations, locale, "")

    attrs =
      [id: translated_input_id(form, field, locale)]
      |> Keyword.merge(attrs)
      |> Keyword.merge(opts)

    tag(tag, translation, attrs)
  end

  @doc ~S"""
  Renders multiple text input HTML elements for the given locales (one for each locale).

  ## Options

  The options allow providing additional HTML attributes, as well as:

    * `:labels` - an anonymous function returning the label for each generated input;
    the locale is given as argument
    * `:wrappers` - an anonymous function returning a custom wrapper for each generated input;
    the locale is given as argument

  ## Example

  ```
  translated_text_inputs(f, :title, [:en, :fr],
    labels: fn locale -> content_tag(:i, locale) end,
    wrappers: fn _locale -> {:div, class: "translated-input-wrapper"} end
  )
  ```
  """
  def translated_text_inputs(form, field, locales_or_gettext_backend, opts \\ [])

  def translated_text_inputs(form, field, gettext_backend, opts) when is_atom(gettext_backend) do
    translated_text_inputs(form, field, Gettext.known_locales(gettext_backend), opts)
  end

  def translated_text_inputs(form, field, locales, opts) do
    translated_fields(&translated_text_input/4, form, field, locales, opts)
  end

  @doc ~S"""
  Renders multiple textarea HTML elements for the given locales (one for each locale).

  For options, see `translated_text_inputs/4`
  """
  def translated_textareas(form, field, locales_or_gettext_backend, opts \\ [])

  def translated_textareas(form, field, gettext_backend, opts) when is_atom(gettext_backend) do
    translated_textareas(form, field, Gettext.known_locales(gettext_backend), opts)
  end

  def translated_textareas(form, field, locales, opts) do
    translated_fields(&translated_textarea/4, form, field, locales, opts)
  end

  @doc ~S"""
  Renders multiple custom HTML elements for the given locales (one for each locale).
  The default element is `div` and may be changed through the `tag` option.

  For options, see `translated_text_inputs/4`
  """
  def translated_elements(form, field, locales_or_gettext_backend, opts \\ [])

  def translated_elements(form, field, gettext_backend, opts) when is_atom(gettext_backend) do
    translated_elements(form, field, Gettext.known_locales(gettext_backend), opts)
  end

  def translated_elements(form, field, locales, opts) do
    translated_fields(&translated_element/4, form, field, locales, opts)
  end

  defp translated_fields(fun, form, field, locales, opts) do
    {get_label_data, opts} = Keyword.pop(opts, :labels, fn locale -> locale end)
    {get_wrapper_data, opts} = Keyword.pop(opts, :wrappers, fn _locale -> nil end)

    Enum.map(locales, fn locale ->
      locale = to_string(locale)

      wrap(get_wrapper_data.(locale), fn ->
        [
          render_label(form, translated_label_for(field, locale), get_label_data.(locale)),
          fun.(form, field, locale, opts)
        ]
      end)
    end)
  end

  defp wrap(nil, render_content), do: render_content.()

  defp wrap({tag, opts}, render_content) do
    PhoenixHTMLHelpers.Tag.content_tag tag, opts do
      render_content.()
    end
  end

  defp render_label(form, field, {{:safe, _} = label, opts}),
    do: safe_render_label(form, field, label, opts)

  defp render_label(form, field, {:safe, _} = label),
    do: safe_render_label(form, field, label, [])

  defp render_label(form, field, {label, opts}),
    do: safe_render_label(form, field, label, opts)

  defp render_label(form, field, label),
    do: safe_render_label(form, field, label, [])

  defp safe_render_label(form, field, label, opts) do
    PhoenixHTMLHelpers.Form.label form, field, opts do
      label
    end
  end

  defp tag(:input = tag, content, attrs) do
    attrs = Keyword.put_new(attrs, :value, content)

    PhoenixHTMLHelpers.Tag.tag(tag, attrs)
  end

  defp tag(tag, content, attrs) do
    PhoenixHTMLHelpers.Tag.content_tag(tag, content, attrs)
  end

  defp translated_input_id(form, field, locale) do
    "#{Form.input_id(form, field)}_#{locale}"
  end

  defp translated_input_name(form, field, locale) do
    "#{Form.input_name(form, field)}[#{locale}]"
  end

  defp translated_label_for(field, locale) do
    "#{field}_#{locale}"
  end
end
