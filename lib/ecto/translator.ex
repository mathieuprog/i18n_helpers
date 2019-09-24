defmodule I18nHelpers.Ecto.Translator do
  @doc ~S"""
  Translates an Ecto struct, a list of Ecto structs or a map containing translations.

  Translating an Ecto struct for a given locale consists of the following steps:

    1. Get the list of the fields that need to be translated from the Schema.
       The Schema must contain a `get_translatable_fields\0` function returning
       a list of those fields.

    2. Get the text for the given locale and store it into a virtual field.
       The Schema must provide, for each translatable field, a corresponding
       virtual field in order to store the translation.

    3. Get the list of the associations that also need to be translated from
       the Schema. The Schema must contain a `get_translatable_assocs\0` function
       returning a list of those associations.

    4. Repeat step 1. for each associated Ecto struct.
  """
  @spec translate(list | struct | map, String.t(), keyword) :: list | struct | String.t() | nil
  def translate(data_structure, locale \\ Gettext.get_locale(), opts \\ [])

  def translate([], _locale, _opts), do: []

  def translate([head | tail], locale, opts) do
    [
      translate(head, locale, opts)
      | translate(tail, locale, opts)
    ]
  end

  def translate(%{__struct__: _struct_name} = entity, locale, opts) do
    fields_to_translate = entity.__struct__.get_translatable_fields()
    assocs_to_translate = entity.__struct__.get_translatable_assocs()

    entity =
      Enum.reduce(fields_to_translate, entity, fn field, updated_entity ->
        virtual_translated_field = String.to_atom("translated_" <> Atom.to_string(field))

        %{^field => translations} = entity

        struct(updated_entity, [
          {virtual_translated_field, translate(translations, locale, opts)}
        ])
      end)

    entity =
      Enum.reduce(assocs_to_translate, entity, fn field, updated_entity ->
        %{^field => assoc} = entity

        case Ecto.assoc_loaded?(assoc) do
          true ->
            struct(updated_entity, [{field, translate(assoc, locale, opts)}])

          _ ->
            updated_entity
        end
      end)

    entity
  end

  def translate(map, _locale, _opts) when map == %{}, do: nil

  def translate(%{} = translations_map, locale, opts) do
    fallback_locale = Keyword.get(opts, :fallback_locale, Gettext.get_locale())

    handle_missing_translation =
      Keyword.get(opts, :handle_missing_translation, fn _, _ -> true end)

    cond do
      has_translation?(translations_map, locale) ->
        translations_map[locale]

      has_translation?(translations_map, fallback_locale) ->
        translation = translations_map[fallback_locale]
        handle_missing_translation.(translations_map, locale)
        translation

      true ->
        handle_missing_translation.(translations_map, locale)
        nil
    end
  end

  defp has_translation?(translations_map, locale),
    do: Map.has_key?(translations_map, locale) && String.trim(locale) != ""

  @doc ~S"""
  Returns a closure allowing to memorize the given options for `translate\3`.
  """
  @doc false
  def set_opts(opts) do
    fn data_structure, overriding_opts ->
      opts = Keyword.merge(opts, overriding_opts)
      locale = Keyword.get(opts, :locale, Gettext.get_locale())

      translate(data_structure, locale, opts)
    end
  end
end
