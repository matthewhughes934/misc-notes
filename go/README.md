# Go

Misc analogous notes about writing/using/running Go

## Unset environment variable in tests

The `testing` package provides
[`T.Setenv`](https://pkg.go.dev/testing#T.Setenv), but doesn't provide an
equivalent for `os.Unsetenv`. However, thanks to the following behaviour of
`T.Setenv`:

> uses Cleanup to restore the environment variable to its original value after
> the test.

We can use:

``` go
// call `Setenv` for the side-effect of restoring the value after the test
t.Setenv(var, "")
// unset the variable for this test run
os.Unsetenv(var)

// test goes here...
```

[credit goes to this
comment](https://github.com/golang/go/issues/52817#issuecomment-1131339120)

## Test run location

From [the docs](https://pkg.go.dev/cmd/go#hdr-Testing_flags):

> When 'go test' runs a test binary, it does so from within the corresponding
> package's source code directory

## CLI structure

Because `main` in Go:

  - Can only set the exit code via a call to `os.Exit`, and
  - Does not take any arguments

And:

  - I want to test return codes (and can't, and don't want to, reassign
    `os.Exit`)
  - I want to test via passing arguments (and don't want to monkey patch
    `os.Args`)

I like to structure my CLI applications like:

``` go
package main

import (
    "context"
    "fmt"
    "io"
    "os"
)

func main() {
    exitCode, err := runApp(context.Background(), os.Stdin, os.Stdout, os.Args)
    if err != nil {
        fmt.Fprintln(os.Stderr, err)
    }

    os.Exit(exitCode)
}

// all the work is done here. Can be tested via injecting args and/or input,
// and the output and returned exit code an error can all be asserted on
func runApp(ctx context.Context, in io.Reader, out io.Writer, args []string) (int, error) {
    return 0, nil
}
```
