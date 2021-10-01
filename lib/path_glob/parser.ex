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

  def alternatives_or(combinator) do
    combinator
    |> replace(ascii_char([?,]), "|")
  end

  def alternatives() do
    alternatives_open()
    |> repeat(
      alternative([?,])
      |> alternatives_or()
    )
    |> alternative([?}])
    |> alternatives_close()
  end

  @special_chars [??, ?*, ?{, ?}, ?[, ?], ?,]

  def literal() do
    @special_chars
    |> Enum.map(&{:not, &1})
    |> utf8_string(min: 1)
    |> map({Regex, :escape, []})
  end

  def special_literal(exclude \\ []) do
    (@special_chars -- exclude)
    |> utf8_string(1)
    |> map({Regex, :escape, []})
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
end
