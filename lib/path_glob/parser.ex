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
    choice(combinator, [
      times(non_alteratives(~W(} ,)), min: 1),
      empty()
    ])
  end

  defp alternatives() do
    punctuation("{")
    |> repeat(alternatives_item() |> punctuation(","))
    |> alternatives_item()
    |> punctuation("}")
    |> tag(:alternatives)
  end

  defp character_item(combinator \\ empty(), exclude) do
    combinator
    |> tag(string_excluding(exclude, 1), :literal)
  end

  defp character_list(exclude) do
    times(character_item(exclude), min: 1)
    |> tag(:character_list)
  end

  defp character_range(exclude) do
    exclude = ["-" | exclude]

    character_item(exclude)
    |> punctuation("-")
    |> character_item(exclude)
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
    string_excluding(@special_chars, min: 1)
    |> tag(:literal)
  end

  defp special_literal(exclude) do
    (@special_chars -- exclude)
    |> to_codepoints()
    |> ascii_string(1)
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
