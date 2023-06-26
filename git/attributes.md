# Git Attributes

## List Files with specific attributes

A `git`
[pathspec](https://git-scm.com/docs/gitglossary#Documentation/gitglossary.txt-aiddefpathspecapathspec)
[accepts `attr:` as a "magic
signature"](https://git-scm.com/docs/gitglossary#Documentation/gitglossary.txt-attr),
allowing you to e.g. list all files with certain attributes:

``` console
$ git ls-files -- ':(attr:diff=golang)'
```

Or, combining with the `exclude` directive, list all files without certain
attributes:

``` console
git ls-files -- ':(attr:diff=golang,exclude)'
```

## Checking attributes on a file

Use `git check-attr`

``` console
$ git check-attr --all tools.go
tools.go: diff: golang
```
