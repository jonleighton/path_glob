# PathGlob

`PathGlob` is a glob library for Elixir.

Elixir’s built-in
[`Path.wildcard/2`](https://hexdocs.pm/elixir/1.12/Path.html#wildcard/2)
function allows you to find all paths that match a certain glob pattern. If
you only want to know whether a _particular_ path matches a glob, then
`Path.wildcard/2` can be slow (depending on the glob), because it needs to
traverse the filesystem.

`PathGlob` provides a `PathGlob.match?/2` function to check a path against a
glob without touching the filesystem. Internally, the glob pattern is compiled
to a `Regex` and then checked via `String.match?/2`. If you want to compile the
glob pattern ahead-of-time, you can use `PathGlob.compile/1`.

## Compatibility

The aim of this library is to closely match the behaviour of `Path.wildcard/2`,
bugs and all. Internally, `Path.wildcard/2` is implemented via Erlang’s
[`filelib:wildcard/2`](http://erlang.org/doc/man/filelib.html#wildcard-1).

There is an extensive test suite, and every assertion is checked against both
`Path.wildcard/2` and `PathGlob.match?/2` to ensure compatibility.

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

## Installation

The package can be installed by adding `path_glob` to your list of dependencies
in `mix.exs`:

```elixir
def deps do
  [
    {:path_glob, "~> 0.1.0"}
  ]
end
```
