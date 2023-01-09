# Inlining

Some notes from when was I debugging some inlining in CPython

## Checking if inlined

The most direct method is of course to just inspect the assembly. Otherwise you
can use the `-fopt-info` flag in `gcc` to display successful inclines via
`-fopt-info-optimized`, e.g.

``` console
CFLAGS='-fopt-info-optimized-inline -O0' make Objects/obmalloc.o  |& grep 'arena_map_get'
Objects/obmalloc.c:866:33: optimized:   Inlining arena_map_get/174 into arena_map_mark_used/175 (always_inline).
Objects/obmalloc.c:841:29: optimized:   Inlining arena_map_get/174 into arena_map_mark_used/175 (always_inline).
Objects/obmalloc.c:883:26: optimized:   Inlining arena_map_get/174 into arena_map_is_used/176 (always_inline)
```

You can also use `nm` to show names in:

``` console
$ nm --demangle Objects/obmalloc.o
```
