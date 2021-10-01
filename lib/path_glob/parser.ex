defmodule PathGlob.Parser do
  import NimbleParsec

  def question() do
    ascii_char([??])
    |> replace(".")
  end

  def star() do
    ascii_char([?*])
    |> replace(".*")
  end

  def alternatives_open() do
    ascii_char([?{])
    |> replace("(")
  end

  def alternatives_close(combinator) do
    combinator
    |> replace(ascii_char([?}]), ")")
  end

  def _or(combinator) do
    combinator
    |> replace(ascii_char([?,]), "|")
  end

  def alternatives() do
    alternatives_open()
    |> repeat(alternative([?,]) |> _or())
    |> alternative([?}])
    |> alternatives_close()
  end

  def characters_open() do
    ascii_char([?[])
    |> replace("(")
  end

  def characters_close(combinator) do
    combinator
    |> replace(ascii_char([?]]), ")")
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
    |> ascii_string([?-], 1)
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

  def special_literal(exclude \\ []) do
    (@special_chars -- exclude)
    |> utf8_string(1)
    |> map(:escape)
  end

  def alternative() do
    alternative([])
  end

  def alternative(exclude) do
    alternative(empty(), exclude)
  end

  def alternative(combinator, exclude) do
    choice(combinator, [
      question(),
      star(),
      characters(),
      literal(),
      special_literal(exclude)
    ])
  end

  def term() do
    choice([
      alternatives(),
      alternative([?{])
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
