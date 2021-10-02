defmodule PathGlob.Parser do
  import NimbleParsec

  defp question() do
    string("?")
    |> replace(".")
  end

  defp double_star_slash() do
    string("**/")
    |> repeat(string("/"))
    |> replace("([^/]+/)*")
  end

  defp double_star() do
    string("**")
    |> repeat(string("/"))
    |> replace("([^/]+/)*[^/]+")
  end

  defp star() do
    string("*")
    |> replace("[^/]*")
  end

  defp alternatives_open() do
    string("{")
    |> replace("(")
  end

  defp alternatives_close(combinator) do
    combinator
    |> replace(string("}"), ")")
  end

  defp _or(combinator) do
    combinator
    |> replace(string(","), "|")
  end

  defp alternatives_item(combinator \\ empty()) do
    choice(combinator, [
      times(non_alteratives([?}, ?,]), min: 1),
      empty()
    ])
  end

  defp alternatives() do
    alternatives_open()
    |> repeat(alternatives_item() |> _or())
    |> alternatives_item()
    |> alternatives_close()
  end

  defp characters_open() do
    string("[")
    |> replace("(")
  end

  defp characters_close(combinator) do
    combinator
    |> replace(string("]"), ")")
  end

  defp character_item(combinator \\ empty(), exclude) do
    exclude = [?- | exclude]

    combinator
    |> map(utf8_string(map_exclude(exclude), 1), :escape)
  end

  defp character_list(exclude) do
    character_item(exclude)
    |> repeat(
      empty()
      |> replace("|")
      |> character_item(exclude)
    )
  end

  defp character_range(exclude) do
    replace(empty(), "[")
    |> times(character_item(exclude), min: 1)
    |> string("-")
    |> times(character_item(exclude), min: 1)
    |> replace(empty(), "]")
  end

  defp character(combinator \\ empty(), exclude) do
    choice(combinator, [
      character_range(exclude),
      character_list(exclude)
    ])
  end

  defp characters() do
    characters_open()
    |> repeat(character([?,, ?]]) |> _or())
    |> character([?]])
    |> characters_close()
  end

  @special_chars [??, ?*, ?{, ?}, ?[, ?], ?,]

  defp map_exclude(chars) do
    Enum.map(chars, &{:not, &1})
  end

  defp literal() do
    @special_chars
    |> map_exclude()
    |> utf8_string(min: 1)
    |> map(:escape)
  end

  defp special_literal(exclude) do
    (@special_chars -- exclude)
    |> utf8_string(1)
    |> map(:escape)
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
      characters(),
      literal(),
      special_literal([?{ | exclude])
    ])
  end

  defp term() do
    choice([
      alternatives(),
      non_alteratives()
    ])
  end

  def escape(string) do
    Regex.escape(string)
  end

  def glob do
    replace(empty(), "^")
    |> repeat(term())
    |> replace(eos(), "$")
  end
end
