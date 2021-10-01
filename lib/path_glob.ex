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
    "^#{parse_chars(glob)}$"
  end

  defp parse_chars("") do
    ""
  end

  defp parse_chars(chars) do
    {first, rest} = String.split_at(chars, 1)
    parse_char(first) <> parse_chars(rest)
  end

  defp parse_char("?"), do: "."
  defp parse_char("*"), do: ".*"
  defp parse_char(char), do: Regex.escape(char)
end
