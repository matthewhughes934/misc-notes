# Debugging the `go` cmd

## Building for debugging go with a given toolchain

Given a toolchain installed following <https://go.dev/doc/manage-install>, `go`
can be built from source using this toolchain via setting the `GOROOT_BOOTSTRAP`
environment variable see [docs](https://go.dev/doc/install/source#go14)(e.g. in
my case the toolchain was downloaded to `~/sdk`). Optimisations and inlining can
also be disabled by setting the `GO_GCFLAGS` variable (see `go doc cmd/compile`
for details)

    GO_GCFLAGS='-N -l' GOROOT_BOOTSTRAP=~/sdk/go1.22.0/ ./make.bash
