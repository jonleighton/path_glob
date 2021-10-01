defmodule PathGlobTest do
  use ExUnit.Case
  doctest PathGlob

  @tmpdir "#{__DIR__}/.tmp"

  test "literal characters" do
    assert_match("foo", "foo")
    refute_match("foo", ["bar", "fo", "FOO"])
  end

  test "? pattern" do
    assert_match("foo", ["?oo", "f?o", "???"])
    refute_match("foo", ["foo?", "f?oo"])
  end

  test "basic * pattern" do
    assert_match("foo", ["*", "f*", "fo*", "foo*", "*foo"])
    refute_match("foo", "b*")
  end

  test "basic {} pattern" do
    assert_match("foo", ["{foo}", "{foo,bar}", "{fo,ba}o"])
    refute_match("foo", ["{bar}", "{bar,baz}", "{b}oo"])
  end

  test "basic [] pattern" do
    assert_match("foo", ["f[o]o", "f[ao]o", "f[a-z]o", "f[o,a]o"])
    refute_match("foo", ["f[a]o", "f[a-d]o", "f[a,b]o"])
  end

  test "special characters in weird places" do
    assert_match("fo,o", ["fo,o", "fo,{o}"])
    assert_error("fo{o", "fo{o")
    assert_match("fo}o", ["fo}o", "fo}{o}"])
    assert_error("fo{o{o}o}", "fo{o{o}o}")
    assert_match("fo[o", "fo[o")
    assert_match("fo]o", "fo]o")
  end

  defp assert_match(path, globs) do
    within_tmpdir(path, fn ->
      for glob <- List.wrap(globs) do
        assert Path.wildcard(glob) == [path]
        assert PathGlob.match?(path, glob)
      end
    end)
  end

  defp refute_match(path, globs) do
    within_tmpdir(path, fn ->
      for glob <- List.wrap(globs) do
        assert Path.wildcard(glob) == []
        refute PathGlob.match?(path, glob)
      end
    end)
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
        File.write!(path, "")
        fun.()
      end)
    after
      File.rm_rf!(tmpdir)
    end
  end
end
