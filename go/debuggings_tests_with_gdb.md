# `go` Debugging Tests with GDB

Compile the package without optimisations of inlining (see `go doc cmd/compile`
for flag meanings):

``` shell
$ go test -gcflags='-N -l' -c path/to/pkg
$ gdb ./pkg.test
```

```
# break on a line
(gdb) break pkg/some_file.go:12
# or a functions
(gdb) break path/to/pkg/file.func
(gdb) info functions path/*
```
