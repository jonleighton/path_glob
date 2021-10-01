defmodule PathGlobTest do
  use ExUnit.Case
  doctest PathGlob

  @tmpdir "#{__DIR__}/.tmp"

  test "literal characters" do
    assert_match("foo", "foo")
    refute_match("foo", ["bar", "fo"])
  end

  test "? pattern" do
    assert_match("foo", ["?oo", "f?o", "???"])
    refute_match("foo", ["foo?", "f?oo"])
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
