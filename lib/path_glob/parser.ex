defmodule PathGlob.Parser do
  import NimbleParsec

  @special_chars ~W(? * { } [ ] , /)

  defp punctuation(combinator \\ empty(), text) do
    combinator
    |> ignore(string(text))
  end

  defp question() do
    string("?")
    |> tag(:question)
  end

  defp double_star_slash() do
    string("**/")
    |> repeat(string("/"))
    |> tag(:double_star_slash)
  end

  defp double_star() do
    string("**")
    |> repeat(string("/"))
    |> tag(:double_star)
  end

  defp dot() do
    choice([
      string(".")
      |> times(string("/"), min: 1)
      |> lookahead_not(eos())
      |> ignore(),
      string(".")
      |> repeat(string("/"))
      |> replace(".")
      |> tag(:literal)
    ])
  end

  defp double_dot() do
    string("..")
    |> choice([
      repeat(string("/"))
      |> lookahead_not(eos())
      |> replace("/"),
      repeat(punctuation("/")) |> lookahead(eos())
    ])
    |> tag(:literal)
  end

  defp star() do
    string("*")
    |> tag(:star)
  end

  defp alternatives_item(combinator \\ empty()) do
    tag(
      combinator,
      choice([
        non_alternatives(),
        char(@special_chars -- ~W({ } ,))
      ])
      |> repeat(),
      :alternatives_item
    )
  end

  defp alternatives() do
    punctuation("{")
    |> repeat(alternatives_item() |> punctuation(","))
    |> alternatives_item()
    |> punctuation("}")
    |> tag(:alternatives)
  end

  defp character(combinator \\ empty(), exclude) do
    tag(
      combinator,
      choice([
        punctuation("\\") |> string("-"),
        string_excluding(exclude, 1)
      ]),
      :literal
    )
  end

  defp character_list(exclude) do
    times(character(exclude), min: 1)
    |> tag(:character_list)
  end

  defp character_range(exclude) do
    exclude = ["-" | exclude]

    character(exclude)
    |> punctuation("-")
    |> character(exclude)
    |> tag(:character_range)
  end

  defp character_class_item(combinator \\ empty(), exclude) do
    times(
      combinator,
      choice([
        character_range(exclude),
        character_list(exclude)
      ]),
      min: 1
    )
  end

  defp character_class() do
    inner =
      character_class_item(~W(, ]))
      |> punctuation(",")
      |> repeat()
      |> character_class_item(~W(]))

    punctuation("[")
    |> choice([
      char("]") |> optional(inner),
      inner
    ])
    |> punctuation("]")
    |> tag(:character_class)
  end

  defp string_excluding(chars, range) do
    chars
    |> to_codepoints()
    |> Enum.map(&{:not, &1})
    |> utf8_string(range)
  end

  defp to_codepoints(chars) do
    Enum.map(chars, fn <<char>> -> char end)
  end

  defp escaped_char() do
    punctuation("\\")
    |> choice([
      punctuation("\\"),
      utf8_string([], 1)
    ])
  end

  defp literal() do
    choice([
      escaped_char(),
      string_excluding(["\\" | @special_chars], min: 1)
    ])
    |> times(min: 1)
    |> tag(:literal)
  end

  defp char(chars) do
    chars
    |> List.wrap()
    |> to_codepoints()
    |> utf8_string(1)
    |> tag(:literal)
  end

  defp non_alternatives() do
    choice([
      question(),
      double_star_slash(),
      double_star(),
      star(),
      double_dot(),
      dot(),
      character_class(),
      literal()
    ])
  end

  defp term() do
    choice([
      alternatives(),
      non_alternatives(),
      char(@special_chars -- ["{"])
    ])
  end

  def glob do
    times(term(), min: 1)
    |> eos()
    |> tag(:glob)
  end
end
