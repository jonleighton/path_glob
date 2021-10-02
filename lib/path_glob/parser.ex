defmodule PathGlob.Parser do
  import NimbleParsec

  def question() do
    string("?")
    |> replace(".")
  end

  def double_star_slash() do
    string("**/")
    |> repeat(string("/"))
    |> replace("([^/]+/)*")
  end

  def double_star() do
    string("**")
    |> repeat(string("/"))
    |> replace("([^/]+/)*[^/]+")
  end

  def star() do
    string("*")
    |> replace("[^/]*")
  end

  def alternatives_open() do
    string("{")
    |> replace("(")
  end

  def alternatives_close(combinator) do
    combinator
    |> replace(string("}"), ")")
  end

  def _or(combinator) do
    combinator
    |> replace(string(","), "|")
  end

  def alternatives() do
    alternatives_open()
    |> repeat(times(non_alteratives([?,]), min: 1) |> _or())
    |> times(non_alteratives([?}]), min: 1)
    |> alternatives_close()
  end

  def characters_open() do
    string("[")
    |> replace("(")
  end

  def characters_close(combinator) do
    combinator
    |> replace(string("]"), ")")
  end

  def character_item(combinator \\ empty(), exclude) do
    combinator
    |> map(utf8_string(map_exclude(exclude), 1), :escape)
  end

  def character_list(exclude) do
    character_item(exclude)
    |> repeat(
      empty()
      |> replace("|")
      |> character_item(exclude)
    )
  end

  def character_range(exclude) do
    replace(empty(), "[")
    |> character_item(exclude)
    |> string("-")
    |> character_item(exclude)
    |> replace(empty(), "]")
  end

  def character(combinator \\ empty(), exclude) do
    choice(combinator, [
      character_range(exclude),
      character_list(exclude)
    ])
  end

  def characters() do
    characters_open()
    |> repeat(character([?,, ?]]) |> _or())
    |> character([?]])
    |> characters_close()
  end

  @special_chars [??, ?*, ?{, ?}, ?[, ?], ?,]

  def map_exclude(chars) do
    Enum.map(chars, &{:not, &1})
  end

  def literal() do
    @special_chars
    |> map_exclude()
    |> utf8_string(min: 1)
    |> map(:escape)
  end

  def special_literal(exclude) do
    (@special_chars -- exclude)
    |> utf8_string(1)
    |> map(:escape)
  end

  def non_alteratives() do
    non_alteratives([])
  end

  def non_alteratives(exclude) do
    non_alteratives(empty(), exclude)
  end

  def non_alteratives(combinator, exclude) do
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

  def term() do
    choice([
      alternatives(),
      non_alteratives()
    ])
  end

  def glob do
    replace(empty(), "^")
    |> repeat(term())
    |> replace(eos(), "$")
  end

  def escape(string) do
    Regex.escape(string)
  end
end
