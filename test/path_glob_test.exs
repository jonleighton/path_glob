defmodule PathGlobTest do
  use ExUnit.Case
  doctest PathGlob

  @tmpdir "#{__DIR__}/.tmp"

  test "literal characters" do
    assert_match("foo", "foo")
    refute_match("foo", "bar")
  end

  defp assert_match(path, glob) do
    within_tmpdir(path, fn ->
      assert Path.wildcard(glob) == [path]
      assert PathGlob.match?(path, glob)
    end)
  end

  defp refute_match(path, glob) do
    within_tmpdir(path, fn ->
      assert Path.wildcard(glob) == []
      refute PathGlob.match?(path, glob)
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
