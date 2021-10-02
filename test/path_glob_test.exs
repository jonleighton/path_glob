defmodule PathGlobTest do
  use ExUnit.Case
  doctest PathGlob

  @tmpdir "#{__DIR__}/.tmp"

  # See also
  # https://github.com/erlang/otp/blob/master/lib/stdlib/test/filelib_SUITE.erl
  # to see the patterns that :filelib.wildcard/2 is tested with (which is used
  # to implement Elixir's Path.wildcard/2).

  test "literal characters" do
    assert_match("foo", ["foo"])
    refute_match("foo", ["bar", "fo", "FOO"])
  end

  test "? pattern" do
    assert_match("foo", ["?oo", "f?o", "f??", "???"])
    refute_match("foo", ["foo?", "f?oo"])
  end

  test "* pattern" do
    assert_match("foo", ["*", "f*", "fo*", "foo*", "*foo"])
    assert_match("foo.ex", ["*", "f*", "foo*", "foo.*", "*.ex", "*ex"])
    assert_match("foo/bar", ["foo/*", "foo/b*", "foo/ba*", "foo/bar*", "foo/*bar", "*/bar"])

    refute_match("foo", ["b*"])
    refute_match("foo/bar", ["foo/f*", "*ar"])
  end

  test "** pattern" do
    assert_match("foo", ["**", "**o", "**/foo", "**//foo"])
    assert_match("foo.ex", ["**", "**o.ex", "**/foo.ex", "**//foo.ex"])
    assert_match("foo/bar", ["**", "**/bar"])
    assert_match("foo/bar.ex", ["**", "**/bar.ex"])
    assert_match("foo/bar/baz", ["**", "**/baz"])
    assert_match("foo/bar/baz.ex", ["**", "**/baz.ex"])

    refute_match("foo/bar", ["**bar"])
    refute_match("foo/bar.ex", ["**bar.ex"])
    refute_match("foo/bar/baz", ["**baz"])
    refute_match("foo/bar/baz.ex", ["**baz.ex"])
  end

  test "{} pattern" do
    assert_match("foo", ["{foo}", "{foo,bar}", "{fo,ba}o", "{*o}", "{*o,*a}", "{f*,a*}"])
    refute_match("foo", ["{bar}", "{bar,baz}", "{b}oo"])
    assert_error("fo{o", ["fo{o"])
    assert_error("fo{o{o}o}", ["fo{o{o}o}"])
    assert_match("fo}o", ["fo}o", "fo}{o}"])
    assert_match("fo,o", ["fo,o", "fo,{o}"])
  end

  test "[] pattern" do
    assert_match("foo", ["f[o]o", "f[ao]o", "f[a-z]o", "f[o,a]o"])
    refute_match("foo", ["f[a]o", "f[a-d]o", "f[a,b]o"])
    assert_match("fo,o", ["fo,o", "fo,[o]"])
    assert_match("fo[o", ["fo[o"])
    assert_match("fo]o", ["fo]o"])
  end

  defp assert_match(path, globs) do
    within_tmpdir(path, fn ->
      for glob <- globs do
        assert path in Path.wildcard(glob)

        assert PathGlob.match?(path, glob),
               "expected '#{glob}' [compiled: #{inspect_compiled(glob)}] to match '#{path}'"
      end
    end)
  end

  defp refute_match(path, globs) do
    within_tmpdir(path, fn ->
      for glob <- globs do
        assert Path.wildcard(glob) == []

        refute PathGlob.match?(path, glob),
               "expected '#{glob}' [compiled: #{inspect_compiled(glob)}] not to match '#{path}'"
      end
    end)
  end

  defp inspect_compiled(glob) do
    glob
    |> PathGlob.compile()
    |> inspect()
  end

  defp assert_error(path, globs) do
    for glob <- List.wrap(globs) do
      try do
        Path.wildcard(glob) == [path]
      rescue
        _ in [ErlangError, CaseClauseError] -> nil
      else
        _ -> raise "expected an error"
      end

      assert_raise(ArgumentError, fn -> PathGlob.match?(path, glob) end)
    end
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
