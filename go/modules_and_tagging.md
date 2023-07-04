# Modules and tagging

Basically just
[this](https://github.com/golang/go/wiki/Modules#publishing-a-release) (but it's
tucked away in a wiki and a bit hard for me to discover).

E.g. for versioning several modules all in one repo with a structure like:

    ├── cmd
    │   ├── first-cmd
    │   │   └── main.go
    │   └── second-cmd
    │       └── main.go
    └── pkg
        ├── bar
        │   └── bar.go
        └── foo

If you wanted to package `cmd/first-cmd` separately to `pkg` then
`cmd/first-cmd` will need to be a stand alone module, i.e.

    .
    ├── cmd
    │   ├── first-cmd
    │   │   ├── main.go
    │   │   ├── mod.go
    │   │   └── sum.go
    │   └── second-cmd
    │       └── main.go
    └── pkg
        ├── bar
        │   └── bar.go
        └── foo
            └── foo.go

Then releases can be made on tags of the form
`path/to/package/cmd/first-cmd/v1.0.0` and installed simply via

    go install path/to/package/cmd/first-cmd@v1.0.0
