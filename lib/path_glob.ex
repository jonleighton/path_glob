defmodule PathGlob do
  @moduledoc """
  Implements glob matching using the same semantics as `Path.wildcard/2`, but
  without any filesystem interaction.
  """

  import PathGlob.Parser
  import NimbleParsec, only: [defparsecp: 3]

  if System.version() >= "1.11" && Code.ensure_loaded?(Mix) && Mix.env() == :test do
    require Logger
    Logger.put_module_level(__MODULE__, :none)

    defmacrop debug(message) do
      quote do
        require Logger
        Logger.debug("PathGlob: " <> unquote(message))
      end
    end
  else
    defmacrop debug(message) do
      quote do
        # Avoid unused variable warning
        _ = fn -> unquote(message) end
        :ok
      end
    end
  end

  defparsecp(:parse, glob(), inline: true)

  @doc """
  Returns whether or not `path` matches the `glob`.

  The glob is first parsed and compiled as a regular expression. If you're
  using the same glob multiple times in performance-critical code, consider
  using `compile/1` and caching the result.

  ## Examples

      iex> PathGlob.match?("lib/path_glob.ex", "{lib,test}/path_*.ex")
      true

      iex> PathGlob.match?("lib/.formatter.exs", "lib/*", match_dot: true)
      true
  """
  def match?(path, glob, opts \\ [])

  @spec match?(String.t(), String.t(), match_dot: boolean()) :: boolean()
  def match?(path, glob, opts) when is_binary(glob) do
    String.match?(path, compile(glob, opts))
  end

  @spec match?(String.t(), Regex.t(), match_dot: boolean()) :: boolean()
  def match?(path, glob, _opts) when is_struct(glob, Regex) do
    String.match?(path, glob)
  end

  @doc """
  Compiles `glob` to a `Regex`.

  Raises `ArgumentError` if `glob` is invalid.

  ## Examples

      iex> PathGlob.compile("{lib,test}/*")
      ~r{^(lib|test)/([^\\./]|(?<=[^/])\\.)*$}

      iex> PathGlob.compile("{lib,test}/path_*.ex", match_dot: true)
      ~r{^(lib|test)/path_[^/]*\\.ex$}
  """
  @spec compile(String.t(), match_dot: boolean()) :: Regex.t()
  def compile(glob, opts \\ []) do
    case parse(glob) do
      {:ok, [parse_tree], "", _, _, _} ->
        regex =
          parse_tree
          |> transform(Keyword.get(opts, :match_dot, false))
          |> Regex.compile!()

        inspect(
          %{
            glob: glob,
            regex: regex,
            parse_tree: parse_tree
          },
          pretty: true
        )
        |> debug()

        regex

      {:error, _, _, _, _, _} = error ->
        debug(inspect(error))
        raise ArgumentError, "failed to parse '#{glob}'"
    end
  end

  defp transform_join(list, match_dot?, joiner \\ "") when is_list(list) do
    list
    |> Enum.map(&transform(&1, match_dot?))
    |> Enum.join(joiner)
  end

  defp transform(token, match_dot?) do
    case token do
      {:glob, terms} ->
        "^#{transform_join(terms, match_dot?)}$"

      {:literal, items} ->
        items
        |> Enum.join()
        |> Regex.escape()

      {:question, _} ->
        any_single(match_dot?)

      {:double_star_slash, _} ->
        pattern = "(#{any_single(match_dot?)}+/)*"

        if match_dot? do
          pattern
        else
          "#{pattern}(?!\\.)"
        end

      {:double_star, _} ->
        "(#{any_single(match_dot?)}+/)*#{any_single(match_dot?)}+"

      {:star, _} ->
        "#{any_single(match_dot?)}*"

      {:alternatives, items} ->
        choice(items, match_dot?)

      {:alternatives_item, items} ->
        transform_join(items, match_dot?)

      {:character_list, items} ->
        transform_join(items, match_dot?, "|")

      {:character_range, [start, finish]} ->
        "[#{transform(start, match_dot?)}-#{transform(finish, match_dot?)}]"

      {:character_class, items} ->
        choice(items, match_dot?)
    end
  end

  defp any_single(match_dot?) do
    if match_dot? do
      "[^/]"
    else
      "([^\\./]|(?<=[^/])\\.)"
    end
  end

  defp choice(items, match_dot?) do
    "(#{transform_join(items, match_dot?, "|")})"
  end
end
