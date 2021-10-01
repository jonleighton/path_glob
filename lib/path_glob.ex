defmodule PathGlob do
  @moduledoc """
  Implements glob matching using the same semantics as `Path.wildcard/2`, but
  without any filesystem interaction.
  """

  import PathGlob.Parser
  import NimbleParsec

  defparsecp(:parse, glob(), inline: true)

  @type path :: String.t()
  @type glob :: String.t()

  @doc """
  Returns whether or not `path` matches the `glob`.

  The glob is first parsed and compiled as a regular expression. If you're
  using the same glob multiple times in performance-critical code, consider
  using `compile/1` and caching the result.
  """
  @spec match?(path(), glob()) :: boolean()
  def match?(path, glob) do
    String.match?(path, compile(glob))
  end

  @doc """
  Compiles `glob` to a `Regex`.

  Raises `ArgumentError` if `glob` is invalid.
  """
  @spec compile(glob()) :: Regex.t()
  def compile(glob) do
    case parse(glob) do
      {:ok, parts, "", _, _, _} ->
        parts
        |> Enum.join()
        |> Regex.compile!()

      {:error, error, _, _, _, _} ->
        raise ArgumentError, "failed to parse '#{glob}': #{error}"
    end
  end
end
