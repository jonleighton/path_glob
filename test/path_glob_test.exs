defmodule PathGlobTest do
  use ExUnit.Case, async: true
  doctest PathGlob

  import PathGlob.MatchHelper
  require PathGlob.MatchHelper

  # See also
  # https://github.com/erlang/otp/blob/master/lib/stdlib/test/filelib_SUITE.erl
  # to see the patterns that :filelib.wildcard/2 is tested with (which is used
  # to implement Elixir's Path.wildcard/2).

  describe "literal characters" do
    test_match("foo", "foo")
    test_no_match("foo", "bar")
    test_no_match("foo", "fo")
    test_no_match("foo", "FOO")
    @tag :pending
    test_no_match(~S(fo\o), ~S(fo\o))
    @tag :pending
    test_no_match(~S(fo\o), ~S(fo\\o))
  end

  describe "? pattern" do
    test_match("foo", "?oo")
    test_match("foo", "f?o")
    test_match("foo", "f??")
    test_match("foo", "???")
    test_no_match("foo", "foo?")
    test_no_match("foo", "f?oo")
  end

  describe "* pattern" do
    test_match("foo", "*")
    test_match("foo", "f*")
    test_match("foo", "fo*")
    test_match("foo", "foo*")
    test_match("foo", "*foo")
    test_match("foo.ex", "*")
    test_match("foo.ex", "f*")
    test_match("foo.ex", "foo*")
    test_match("foo.ex", "foo.*")
    test_match("foo.ex", "*.ex")
    test_match("foo.ex", "*ex")
    test_match("foo/bar", "foo/*")
    test_match("foo/bar", "foo/b*")
    test_match("foo/bar", "foo/ba*")
    test_match("foo/bar", "foo/bar*")
    test_match("foo/bar", "foo/*bar")
    test_match("foo/bar", "*/bar")
    test_match("foo/bar", "*/*")
    test_match("foo/bar.ex", "foo/*.ex")
    test_match("foo/bar.ex", "foo/*")
    test_no_match("foo", "b*")
    test_no_match("foo/bar", "foo/f*")
    test_no_match("foo/bar", "*ar")
    test_no_match("foo/bar", "baz/*")
  end

  describe "** pattern" do
    test_match("foo", "**")
    test_match("foo", "**o")
    test_match("foo", "**/foo")
    test_match("foo", "**//foo")
    test_match("foo.ex", "**")
    test_match("foo.ex", "**o.ex")
    test_match("foo.ex", "**/foo.ex")
    test_match("foo.ex", "**//foo.ex")
    test_match("foo/bar", "**")
    test_match("foo/bar", "**/bar")
    test_match("foo/bar", "foo/**")
    test_match("foo/bar.ex", "**")
    test_match("foo/bar.ex", "**/bar.ex")
    test_match("foo/bar.ex", "foo/**")
    test_match("foo/bar.ex", "foo/**.ex")
    test_match("foo/bar/baz", "**")
    test_match("foo/bar/baz", "**/baz")
    test_match("foo/bar/baz.ex", "**")
    test_match("foo/bar/baz.ex", "**/baz.ex")
    test_match("foo/bar/baz.ex", "**/bar/**")
    test_match("foo/bar/baz.ex", "**/bar/**.ex")
    test_no_match("foo/bar", "**bar")
    test_no_match("foo/bar", "foo**")
    test_no_match("foo/bar.ex", "**bar.ex")
    test_no_match("foo/bar/baz", "**baz")
    test_no_match("foo/bar/baz.ex", "**baz.ex")
    test_no_match("foo/bar/baz.ex", "**/baz/**")
    test_no_match("foo/bar/baz.ex", "**/baz/**.ex")
  end

  describe "{} pattern" do
    test_match("foo", "{foo}")
    test_match("foo", "{foo,bar}")
    test_match("foo", "{fo,ba}o")
    test_match("foo", "{*o}")
    test_match("foo", "{*o,*a}")
    test_match("foo", "{f*,a*}")
    test_no_match("foo", "{bar}")
    test_no_match("foo", "{bar,baz}")
    test_no_match("foo", "{b}oo")
    test_error("fo{o", "fo{o", ErlangError)
    test_error("fo{o{o}o}", "fo{o{o}o}", CaseClauseError)
    test_match("fo}o", "fo}o")
    test_match("fo}o", "fo}{o}")
    test_match("fo}o", "{f}o}o")
    test_match("fo,o", "fo,o")
    test_match("fo,o", "fo,{o}")
    test_match("abcdef", "a*{def,}")
    test_match("abcdef", "a*{,def}")
    test_match("{abc}", ~S(\{a*))
    test_match("{abc}", ~S(\{abc}))
    test_match("@a,b", ~S(@{a\,b,c}))
    test_match("@c", ~S(@{a\,b,c}))
    test_match("?q", ~S(\?q))
  end

  describe "[] pattern" do
    test_match("foo", "f[o]o")
    test_match("foo", "f[ao]o")
    test_match("foo", "f[a-z]o")
    test_match("foo", "f[o,a]o")
    test_no_match("foo", "f[a]o")
    test_no_match("foo", "f[a-d]o")
    test_no_match("foo", "f[a,b]o")
    test_no_match("foo", "foo[]")
    test_match("fo,o", "fo,o")
    test_match("fo,o", "fo,[o]")
    test_match("fo[o", "fo[o")
    test_match("fo]o", "fo]o")
    test_match("foo123", "foo[1]23")
    test_match("foo123", "foo[1-9]23")
    test_match("foo123", "foo[1-39]23")
    test_match("foo923", "foo[1-39]23")
    test_no_match("foo123", "foo[12]3")
    test_no_match("foo123", "foo[1-12]3")
    test_no_match("foo123", "foo[1-123]")
    test_match("a-", "a-")
    test_match("a-", "a[-]")
    test_match("a-", "a[A-C-]")
    test_match("a-", "a[][A-C-]")
    test_match("a[", "a[")
    test_match("a[", "a[[]")
    test_match("a[", "a[a[]")
    test_match("a[", "a[[a]")
    test_match("a[", "a[a[b]")
    test_match("a]", "a]")
    test_match("a]", "a[]a]")
    test_match("a]", "a[]]")
    test_no_match("a]", "a[b,]a]")
    test_no_match("a]", "a[a-z]]")
    test_no_match("a]", "a[a]b]")
    test_no_match("a]", "a[a]]")
    test_match("---", ~S([a\-z]*))
    test_match("abc", ~S([a\-z]*))
    test_match("z--", ~S([a\-z]*))
    @tag :pending
    test_no_match(~S(\a), ~S([a\-z]*))
  end

  describe "combinations" do
    test_match("foo/bar", "{foo,baz}/*")
    test_match("foo/bar", "**/*")
    test_match("foo/bar/baz", "**/*")
  end
end
