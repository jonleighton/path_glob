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
    |> repeat(alternative() |> alternatives_or())
    |> alternative()
    |> alternatives_close()
  end

  # FIXME: , should match outside of alternatives?
  def literal() do
    [??, ?*, ?{, ?}, ?[, ?], ?,]
    |> Enum.map(&{:not, &1})
    |> utf8_string(min: 1)
    |> map({Regex, :escape, []})
  end

  def alternative(combinator \\ empty()) do
    choice(combinator, [
      question(),
      star(),
      literal()
    ])
  end

  def term() do
    choice([alternative(), alternatives()])
  end

  def glob do
    replace(empty(), "^")
    |> repeat(term())
    |> replace(eos(), "$")
  end
end
