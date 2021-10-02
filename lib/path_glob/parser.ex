defmodule PathGlob.Parser do
  import NimbleParsec

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

  defp star() do
    string("*")
    |> tag(:star)
  end

  defp alternatives_item(combinator \\ empty()) do
    combinator
    |> tag(
      choice([
        times(non_alteratives(~W(} ,)), min: 1),
        empty()
      ]),
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
    combinator
    |> tag(
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
      repeat(character_class_item(~W(, ])) |> punctuation(","))
      |> character_class_item(~W(]))

    punctuation("[")
    |> choice([string("]") |> tag(:literal) |> optional(inner), inner])
    |> punctuation("]")
    |> tag(:character_class)
  end

  @special_chars ~W(? * { } [ ] ,)

  defp string_excluding(chars, range) do
    chars
    |> to_codepoints()
    |> Enum.map(&{:not, &1})
    |> ascii_string(range)
  end

  defp to_codepoints(chars) do
    Enum.map(chars, fn <<char>> -> char end)
  end

  defp literal() do
    times(
      choice([
        punctuation("\\") |> special_literal([]),
        string_excluding(["\\" | @special_chars], min: 1) |> tag(:literal)
      ]),
      min: 1
    )
  end

  defp special_literal(combinator \\ empty(), exclude) do
    combinator
    |> ascii_string(to_codepoints(@special_chars -- exclude), 1)
    |> tag(:literal)
  end

  defp non_alteratives() do
    non_alteratives([])
  end

  defp non_alteratives(exclude) do
    non_alteratives(empty(), exclude)
  end

  defp non_alteratives(combinator, exclude) do
    choice(combinator, [
      question(),
      double_star_slash(),
      double_star(),
      star(),
      character_class(),
      literal(),
      special_literal(["{" | exclude])
    ])
  end

  defp term() do
    choice([
      alternatives(),
      non_alteratives()
    ])
  end

  def glob do
    repeat(term())
    |> eos()
    |> tag(:glob)
  end
end
