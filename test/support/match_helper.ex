defmodule PathGlob.MatchHelper do
  @tmpdir "#{__DIR__}/../.tmp"

  import ExUnit.Assertions

  defmacro test_match(path, glob) do
    quote do
      test "glob '#{unquote(glob)}' matches path '#{unquote(path)}'" do
        assert_match(unquote(path), unquote(glob))
      end
    end
  end

  defmacro test_no_match(path, glob) do
    quote do
      test "glob '#{unquote(glob)}' doesn't match path '#{unquote(path)}'" do
        refute_match(unquote(path), unquote(glob))
      end
    end
  end

  defmacro test_error(path, glob, wildcard_exception) do
    quote do
      test "glob '#{unquote(glob)}' raises an error" do
        assert_error(unquote(path), unquote(glob), unquote(wildcard_exception))
      end
    end
  end

  def assert_match(path, glob) do
    within_tmpdir(path, fn ->
      assert path in Path.wildcard(glob),
             "expected Path.wildcard(#{inspect(glob)}) to include '#{path}'"

      assert PathGlob.match?(path, glob),
             "expected '#{glob}' [compiled: #{inspect_compiled(glob)}] to match '#{path}'"
    end)
  end

  def refute_match(path, glob) do
    within_tmpdir(path, fn ->
      assert path not in Path.wildcard(glob),
             "expected Path.wildcard(#{inspect(glob)}) not to include '#{path}'"

      refute PathGlob.match?(path, glob),
             "expected '#{glob}' [compiled: #{inspect_compiled(glob)}] not to match '#{path}'"
    end)
  end

  defp inspect_compiled(glob) do
    glob
    |> PathGlob.compile()
    |> inspect()
  end

  def assert_error(path, glob, wildcard_exception) do
    try do
      Path.wildcard(glob) == [path]
    rescue
      e -> assert is_exception(e, wildcard_exception)
    else
      _ -> raise "expected an error"
    end

    assert_raise(ArgumentError, fn -> PathGlob.match?(path, glob) end)
  end

  defp within_tmpdir(path, fun) do
    tmpdir = Path.join(@tmpdir, Enum.take_random(?a..?z, 10))
    File.mkdir_p!(tmpdir)

    try do
      File.cd!(tmpdir, fn ->
        dir = Path.dirname(path)
        unless dir == ".", do: File.mkdir_p!(dir)
        File.write!(path, "")
        fun.()
      end)
    after
      File.rm_rf!(tmpdir)
    end
  end
end