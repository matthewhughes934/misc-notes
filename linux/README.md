# Linux

Misc notes from working on Linux machines

# Argument list too long

What is the actual limit here? From my understanding, it's the smallest of:

  - `echo $(( $(getconf PAGESIZE) * 32 ))` (i.e. `MAX_ARG_STRLEN` in the kernel)
    [ref](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/tree/include/uapi/linux/binfmts.h?id=861c0981648f5b64c86fd028ee622096eb7af05a),
    and
  - `getconf ARG_MAX` [ref](https://man.archlinux.org/man/sysconf.3.en#ARG_MAX)
