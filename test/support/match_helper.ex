defmodule PathGlob.MatchHelper do
  @tmpdir "#{__DIR__}/../.tmp"

  import ExUnit.Assertions

  defmacro test_match(path, glob, opts \\ []) do
    quote do
      test "glob '#{unquote(glob)}' matches path '#{unquote(path)}'" do
        within_tmpdir(unquote(path), fn ->
          assert_match(unquote(path), unquote(glob), unquote(opts))
        end)
      end
    end
  end

  defmacro test_no_match(path, glob, opts \\ []) do
    quote do
      test "glob '#{unquote(glob)}' doesn't match path '#{unquote(path)}'" do
        within_tmpdir(unquote(path), fn ->
          refute_match(unquote(path), unquote(glob), unquote(opts))
        end)
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

  def assert_match(path, glob, opts \\ []) do
    assert path in Path.wildcard(glob, opts),
           "expected #{wildcard_call(glob, opts)} to include '#{path}'"

    assert PathGlob.match?(glob, path, opts),
           "expected '#{glob}' to match '#{path}'"
  end

  def refute_match(path, glob, opts \\ []) do
    assert path not in Path.wildcard(glob, opts),
           "expected #{wildcard_call(glob, opts)} not to include '#{path}'"

    refute PathGlob.match?(glob, path, opts),
           "expected '#{glob}' not to match '#{path}'"
  end

  defp wildcard_call(glob, opts) do
    "Path.wildcard(#{inspect(glob)}, #{inspect(opts)})"
  end

  def assert_error(path, glob, wildcard_exception) do
    try do
      Path.wildcard(glob) == [path]
    rescue
      exception ->
        # This can be changed to is_exception when we drop Elixir 1.10 support
        assert match?(
                 %{__struct__: ^wildcard_exception, __exception__: true},
                 exception
               )
    else
      _ -> raise "expected an error"
    end

    assert_raise(ArgumentError, fn -> PathGlob.match?(glob, path) end)
  end

  def within_tmpdir(path, fun) do
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
