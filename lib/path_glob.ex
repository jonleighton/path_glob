defmodule PathGlob do
  @doc """
  TODO
  """
  def match?(path, glob) do
    String.match?(path, compile!(glob))
  end

  defp compile!(glob) do
    glob
    |> parse()
    |> Regex.compile!()
  end

  defp parse(glob) do
    "^(#{parse_chars(glob, [], "")})$"
  end

  defp parse_chars("", _stack, _saved) do
    ""
  end

  defp parse_chars(chars, stack, saved) do
    {first, rest} = String.split_at(chars, 1)
    {first, stack} = parse_char(first, stack, saved)

    if Enum.empty?(stack) do
      first <> parse_chars(rest, stack, saved)
    else
      parse_chars(rest, stack, first <> saved)
    end
  end

  defp parse_char("?", stack, _) do
    {".", stack}
  end

  defp parse_char("*", stack, _) do
    {".*", stack}
  end

  defp parse_char("{", stack, _) do
    {"(", ["{" | stack]}
  end

  defp parse_char("}", ["{" | stack], saved) do
    {String.reverse(")" <> saved), stack}
  end

  defp parse_char(",", ["{" | _] = stack, _) do
    {"|", stack}
  end

  defp parse_char(char, stack, _) do
    {Regex.escape(char), stack}
  end
end
