defmodule PathGlob do
  import PathGlob.Parser
  import NimbleParsec

  defparsecp(:parse, glob(), inline: true)

  @doc """
  TODO
  """
  def match?(path, glob) do
    String.match?(path, compile!(glob))
  end

  defp compile!(glob) do
    case parse(glob) do
      {:ok, parts, "", _, _, _} ->
        parts
        |> Enum.join()
        |> IO.inspect()
        |> Regex.compile!()

      {:error, error, _, _, _, _} ->
        raise ArgumentError, "failed to parse '#{glob}': #{error}"
    end
  end
end
