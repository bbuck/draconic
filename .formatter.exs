locals_without_parens = [
  name: 1,
  desc: 1,
  short_desc: 1,
  subcommand: 1,
  string_flag: 2,
  string_flag: 3,
  int_flag: 2,
  int_flag: 3,
  bool_flag: 2,
  bool_flag: 3,
  float_flag: 2,
  float_flag: 3,
  flag: 3,
  flag: 4,
  command: 1
]


# Used by "mix format"
[
  inputs: ["mix.exs", "{config,lib,test}/**/*.{ex,exs}"],
  locals_without_parens: locals_without_parens,
  export: [locals_without_parens: locals_without_parens]
]
