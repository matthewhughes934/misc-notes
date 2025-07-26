# Debugging tests

Compile tests and then debug them under `rust-gdb`:

``` console
$ cargo test --no-run
$ rust-gdb --args ./target/debug/deps/<name> -- --exact <test-name>
```
