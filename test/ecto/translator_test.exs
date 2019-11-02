defmodule I18nHelpers.Ecto.TranslatorTest do
  use ExUnit.Case, async: true

  alias I18nHelpers.Ecto.Translator
  alias I18nHelpers.Ecto.TranslatableFields

  doctest Translator

  defmodule Category do
    use Ecto.Schema
    use TranslatableFields

    schema "categories" do
      field(:name, :map)
      translatable_field :name
      translatable_belongs_to :parent_category, Category
      translatable_many_to_many :menus, Menu, join_through: "categories_menus"
    end
  end

  defmodule Post do
    use Ecto.Schema
    use TranslatableFields

    schema "posts" do
      translatable_field :title
      translatable_field :body
      translatable_has_many :comments, Comment
      translatable_belongs_to :category, Category
    end
  end

  defmodule Comment do
    @behaviour I18nHelpers.Ecto.TranslatableFields

    use Ecto.Schema

    schema "comments" do
      field(:text, :map)
      field(:translated_text, :string, virtual: true)
      has_one(:state, State)
    end

    def get_translatable_fields, do: [:text]
    def get_translatable_assocs, do: [:state]
  end

  defmodule State do
    use Ecto.Schema
    use TranslatableFields

    schema "states" do
      translatable_field :name
    end
  end

  defmodule Menu do
    use Ecto.Schema
    use TranslatableFields

    schema "menus" do
      translatable_field :label
    end
  end

  defmodule MyTranslator do
    def translate(data_structure, locale \\ Gettext.get_locale(), opts \\ []) do
      handle_missing_translation =
        Keyword.get(opts, :handle_missing_translation, &handle_missing_translation/2)

      opts = Keyword.put(opts, :handle_missing_translation, handle_missing_translation)

      Translator.translate(data_structure, locale, opts)
    end

    def handle_missing_translation(translations_map, locale) do
      raise "missing translation for locale `#{locale}` in #{inspect(translations_map)}"
    end
  end

  test "get translation from empty map" do
    assert Translator.translate(%{}) == nil
    assert Translator.translate(%{}, "fr") == nil
  end

  test "get translation from map, given key is present" do
    assert Translator.translate(%{"en" => "hello", "fr" => "bonjour"}) == "hello"
    assert Translator.translate(%{"en" => "hello", "fr" => "bonjour"}, "en") == "hello"
    assert Translator.translate(%{"en" => "hello", "fr" => "bonjour"}, "fr") == "bonjour"
    assert Translator.translate(%{"en" => "hello", "fr" => "bonjour"}, :fr) == "bonjour"
  end

  test "get translation from map, given key is missing" do
    assert Translator.translate(%{"en" => "hello"}, "nl") == "hello"

    Gettext.put_locale("nl")
    assert Translator.translate(%{"en" => "hello"}) == nil
  end

  test "option: fallback locale" do
    assert Translator.translate(%{"fr" => "bonjour"}, "en") == nil
    assert Translator.translate(%{"fr" => "bonjour"}, "en", fallback_locale: "fr") == "bonjour"
    assert Translator.translate(%{"fr" => "bonjour"}, :en, fallback_locale: :fr) == "bonjour"
  end

  test "option: missing translation handler" do
    Translator.translate(%{"fr" => "bonjour"}, "en",
      handle_missing_translation: fn translations_map, locale ->
        assert translations_map == %{"fr" => "bonjour"}
        assert locale == "en"
      end
    )
  end

  test "get translations from list of maps" do
    assert Translator.translate([
             %{"en" => "hello", "fr" => "bonjour"},
             %{"en" => "world", "nl" => "wereld"},
             %{"fr" => "toto"}
           ]) == [
             "hello",
             "world",
             nil
           ]

    assert Translator.translate(
             [
               %{"en" => "hello", "fr" => "bonjour"},
               %{"en" => "world", "nl" => "wereld"},
               %{"fr" => "toto"}
             ],
             "fr",
             fallback_locale: "nl"
           ) == [
             "bonjour",
             "wereld",
             "toto"
           ]
  end

  test "translate struct" do
    post = %Post{
      title: %{"en" => "The title", "fr" => "Le titre"},
      body: %{"en" => "The content", "fr" => "Le contenu"}
    }

    assert post.translated_title == nil

    translated_post = Translator.translate(post, "en")

    assert translated_post.translated_title == "The title"
    assert translated_post.translated_body == "The content"
  end

  test "translate struct with associations" do
    comment =
      %Comment{text: %{"en" => "A comment", "fr" => "Un commentaire"}}
      |> Map.put(:state, %State{
        name: %{"en" => "Pending validation", "fr" => "En attente de validation"}
      })

    category =
      %Category{name: %{"en" => "The category", "fr" => "La catégorie"}}
      |> Map.put(:parent_category, %Category{
        name: %{"en" => "The parent category", "fr" => "La catégorie mère"}
      })
      |> Map.put(:menus, [
        %Menu{
          label: %{"en" => "A menu", "fr" => "Un menu"}
        },
        %Menu{
          label: %{"en" => "Another menu", "fr" => "Un autre menu"}
        }
      ])

    post =
      %Post{
        title: %{"en" => "The title", "fr" => "Le titre"},
        body: %{"en" => "The content", "fr" => "Le contenu"}
      }
      |> Map.put(:comments, [comment])
      |> Map.put(:category, category)

    translated_post = Translator.translate(post, :fr)

    assert translated_post.translated_title == "Le titre"
    assert translated_post.translated_body == "Le contenu"
    assert hd(translated_post.comments).translated_text == "Un commentaire"
    assert hd(translated_post.comments).state.translated_name == "En attente de validation"
    assert translated_post.category.translated_name == "La catégorie"
    assert translated_post.category.parent_category.translated_name == "La catégorie mère"
    assert hd(translated_post.category.menus).translated_label == "Un menu"
  end

  test "translate with opts" do
    translate = Translator.set_opts(fallback_locale: "fr")

    assert translate.(%{"fr" => "bonjour", "nl" => "hallo"}, locale: "en") == "bonjour"

    assert translate.(%{"fr" => "bonjour", "nl" => "hallo"}, locale: "en", fallback_locale: :nl) ==
             "hallo"

    assert translate.(%{"fr" => "bonjour", "nl" => "hallo"}, []) == "bonjour"
  end

  test "translate with custom translator" do
    assert_raise RuntimeError,
                 ~r"missing translation for locale `en` in %{\"fr\" => \"bonjour\"}",
                 fn ->
                   MyTranslator.translate(%{"fr" => "bonjour"}, "en") == nil
                 end
  end
end
