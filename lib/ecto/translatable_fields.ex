defmodule I18nHelpers.Ecto.TranslatableFields do
  @moduledoc ~S"""
  Provides macros for defining translatable fields and associations.

  This module's purpose is to provide the `I18nHelpers.Ecto.Translator` module
  with a way to access the list of fields and associations from the Ecto Schema
  that needs to be translated, and with virtual fields allowing to store the
  translations for the current locale.

  `__using__\1` this module provides the caller module with two functions:
  `get_translatable_fields\0` and `get_translatable_assocs\0` listing all the
  translatable fields and the translatable associations respectively.

  Fields that are to be translated are expected to hold maps

      field :title, :map

  where each key represents a locale and each value contains the text for
  that locale. Below is an example of such map:

      %{
        "en" => "My Favorite Books",
        "fr" => "Mes Livres Préférés",
        "nl" => "Mijn Lievelingsboeken",
        "en-GB" => "My Favourite Books"
      }

  Each of those fields must come with a virtual field which is used to
  hold the translation for the current locale.

      field :title, :map
      field :translated_title, :string, virtual: true

  Such a translatable field must be included in the translatable fields list:

      def get_translatable_fields, do: [:title]

  This module provides the macro `translatable_field\1` which allows to execute
  those three steps above (add the field as `:map`, add the virtual field and
  add the field to the translatable fields list) in one line:

      translatable_field :title

  Macros marking associations as translatable are also provided:

    * translatable_belongs_to\2
    * translatable_has_many\2
    * translatable_has_one\2
    * translatable_many_to_many\3

  The macros above add the given association field name to the translatable
  associations list, which is accessible with `get_translatable_assocs\0`.
  """

  alias I18nHelpers.Ecto.TranslatableType

  @callback get_translatable_fields() :: [atom]
  @callback get_translatable_assocs() :: [atom]

  defmacro __using__(_args) do
    this_module = __MODULE__

    quote do
      @behaviour unquote(this_module)

      import unquote(this_module),
        only: [
          translatable_field: 1,
          translatable_belongs_to: 2,
          translatable_has_many: 2,
          translatable_has_one: 2,
          translatable_many_to_many: 3
        ]

      Module.register_attribute(__MODULE__, :translatable_fields, accumulate: true)
      Module.register_attribute(__MODULE__, :translatable_assocs, accumulate: true)

      @before_compile unquote(this_module)
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      def get_translatable_fields(), do: @translatable_fields
      def get_translatable_assocs(), do: @translatable_assocs
    end
  end

  @doc ~S"""
  Defines a translatable field on the schema.

  This macro will generate two fields:

    * a field with the given name and type `:map` and
    * a virtual field with the given name prepended by `"translated_"` and type `:string`.

  For example

      translatable_field :title

  will generate

      field :title, :map
      field :translated_title, :string, virtual: true

  The macro will add the given field name into the translatable fields list.
  """
  defmacro translatable_field(field_name) do
    quote do
      fields = Module.get_attribute(__MODULE__, :struct_fields)

      unless List.keyfind(fields, unquote(field_name), 0) do
        field(unquote(field_name), TranslatableType)
      end

      field(String.to_atom("translated_" <> Atom.to_string(unquote(field_name))), :string,
        virtual: true
      )

      Module.put_attribute(__MODULE__, :translatable_fields, unquote(field_name))
    end
  end

  @doc ~S"""
  Defines a translatable `belongs_to` association.

  The macro will add the given field name into the translatable associations list.
  """
  defmacro translatable_belongs_to(field_name, module_name) do
    quote do
      belongs_to(unquote(field_name), unquote(module_name))

      Module.put_attribute(__MODULE__, :translatable_assocs, unquote(field_name))
    end
  end

  @doc ~S"""
  Defines a translatable `has_many` association.

  The macro will add the given field name into the translatable associations list.
  """
  defmacro translatable_has_many(field_name, module_name) do
    quote do
      has_many(unquote(field_name), unquote(module_name))

      Module.put_attribute(__MODULE__, :translatable_assocs, unquote(field_name))
    end
  end

  @doc ~S"""
  Defines a translatable `has_one` association.

  The macro will add the given field name into the translatable associations list.
  """
  defmacro translatable_has_one(field_name, module_name) do
    quote do
      has_one(unquote(field_name), unquote(module_name))

      Module.put_attribute(__MODULE__, :translatable_assocs, unquote(field_name))
    end
  end

  @doc ~S"""
  Defines a translatable `many_to_many` association.

  The macro will add the given field name into the translatable associations list.
  """
  defmacro translatable_many_to_many(field_name, module_name, opts \\ []) do
    quote do
      many_to_many(unquote(field_name), unquote(module_name), unquote(opts))

      Module.put_attribute(__MODULE__, :translatable_assocs, unquote(field_name))
    end
  end
end
