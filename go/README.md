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
