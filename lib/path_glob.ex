defmodule PathGlob do
  @moduledoc """
  Implements glob matching using the same semantics as `Path.wildcard/2`, but
  without any filesystem interaction.
  """

  import PathGlob.Parser
  import NimbleParsec

  require Logger
  Logger.put_module_level(__MODULE__, :none)

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
      {:ok, [parse_tree], "", _, _, _} ->
        regex =
          parse_tree
          |> transform()
          |> Regex.compile!()

        Logger.debug(
          inspect(
            %{
              glob: glob,
              regex: regex,
              parse_tree: parse_tree
            },
            pretty: true
          )
        )

        regex

      {:error, _error, _, _, _, _} ->
        raise ArgumentError, "failed to parse '#{glob}'"
    end
  end

  defp transform_join(list, joiner \\ "") when is_list(list) do
    list
    |> Enum.map(&transform/1)
    |> Enum.join(joiner)
  end

  defp transform(token) do
    case token do
      {:glob, terms} ->
        "^#{transform_join(terms)}$"

      {:literal, [string]} ->
        Regex.escape(string)

      {:question, _} ->
        "."

      {:double_star_slash, _} ->
        "([^/]+/)*"

      {:double_star, _} ->
        "([^/]+/)*[^/]+"

      {:star, _} ->
        "[^/]*"

      {:alternatives, items} ->
        "(#{transform_join(items, "|")})"

      {:character_list, items} ->
        transform_join(items, "|")

      {:character_range, [start, finish]} ->
        "[#{transform(start)}-#{transform(finish)}]"

      {:character_class_item, items} ->
        "(#{transform_join(items, "|")})"
    end
  end
end
