# PathGlob

[![Actions Status](https://github.com/jonleighton/path_glob/actions/workflows/elixir.yml/badge.svg)](https://github.com/jonleighton/elixir/actions)
[![Module Version](https://img.shields.io/hexpm/v/path_glob.svg)](https://hex.pm/packages/path_glob)
[![Hex Docs](https://img.shields.io/badge/hex-docs-lightgreen.svg)](https://hexdocs.pm/path_glob/)

`PathGlob` tests whether a file path matches a glob pattern, without touching
the filesystem. It has the same semantics as `Path.wildcard/2`.

`Path.wildcard/2` allows you to find all paths that match a certain glob
pattern. If you only want to know whether a _particular_ path matches a glob,
then `Path.wildcard/2` can be slow (depending on the glob), because it needs to
traverse the filesystem.

`PathGlob` provides a `PathGlob.match?/3` function to check a path against a
glob without touching the filesystem. Internally, the glob pattern is compiled
to a `Regex` and then checked via `String.match?/2`. If you want to compile the
glob pattern ahead-of-time, you can use `PathGlob.compile/2`.

## Usage

```elixir
# when using precompiled glob
iex> PathGlob.compile("{foo,bar}") |> PathGlob.match?("foo")


# with string input (slower on multiple matches with the same pattern)
iex> PathGlob.match?("{foo,bar}", "foo")
```

## Installation

The package can be installed by adding `path_glob` to your list of dependencies
in `mix.exs`:

```elixir
def deps do
  [
    {:path_glob, "~> 0.2.0"}
  ]
end
```

## Compatibility

The aim of this library is to closely match the behaviour of `Path.wildcard/2`,
bugs and all. Internally, `Path.wildcard/2` is implemented via Erlang’s
[`filelib:wildcard/2`](http://erlang.org/doc/man/filelib.html#wildcard-1).

There is an extensive test suite, and every assertion is checked against both
`Path.wildcard/2` and `PathGlob.match?/3` to ensure compatibility.

Elixir >= 1.10 is supported. The CI currently runs against:

* Elixir 1.10 / OTP 22
* Elixir 1.11 / OTP 23
* Elixir 1.12 / OTP 24

## Caveats

Some behaviour is not identical to `Path.wildcard/2`:

### Exceptions

Certain weird inputs (e.g. `fo{o`) cause `Path.wildcard/2` to raise an
exception. A variety of different exceptions (`ErlangError`, `CaseClauseError`,
`MatchError`, ...) may be raised.

`PathGlob` aims to always raise an exception on the same inputs as
`Path.wildcard/2`, but it will always be an `ArgumentError`.

### Directory traversal

`Path.wildcard/2` has an undocumented feature for directory traversal in the
glob. For example, a glob of `/foo/bar/../a` would return the path
`/foo/bar/../a`, which is the same as `/foo/a`. There is logic to check that
`/foo/bar` is actually a directory before traversing.

`PathGlob` implements this pattern, but because it doesn’t interact with the
filesystem, it doesn’t check whether the pattern is actually valid in relation
to the contents of the filesystem.

## Alternatives

* [ex_minimatch](https://github.com/gniquil/ex_minimatch) is a port of a
  JavaScript library, and so doesn’t target compatibility with
  `Path.wildcard/2`. It also appears to be an abandoned project.

## License

PathGlob is released under the [Apache License 2.0](LICENSE).
