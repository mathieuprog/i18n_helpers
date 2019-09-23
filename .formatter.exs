locals_without_parens = [
  translatable_field: 1,
  translatable_belongs_to: 2,
  translatable_has_many: 2,
  translatable_has_one: 2,
  translatable_many_to_many: 3
]

[
  inputs: ["{mix,.formatter}.exs", "{config,lib,test}/**/*.{ex,exs}"],
  locals_without_parens: locals_without_parens,
  export: [
    locals_without_parens: locals_without_parens
  ]
]
