# Linux

## `execve` limits

I.e. `Argument list too long` error. Most frequently encountered in GitHub
actions when trying to pass large arguments down to other actions. [The
docs](https://man.archlinux.org/man/execve.2.en#E2BIG) say:

> The total number of bytes in the environment (envp) and argument list (argv)
> is too large, an argument or environment string is too long, or the full
> pathname of the executable is too long. The terminating null byte is counted
> as part of the string length.

Of note, it includes *environment variables* as well as the argument list.

This limit are defined [in
`include/uapi/linux/binfmts.h`](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/tree/include/uapi/linux/binfmts.h?id=861c0981648f5b64c86fd028ee622096eb7af05a)
and is the smallest of:

  - `echo $(( $(getconf PAGESIZE) * 32 ))`, i.e. `MAX_ARG_STRLEN` in that link
  - `getconf ARG_MAX`\[3\], see
    [`sysconf(3)`](https://man.archlinux.org/man/sysconf.3.en) and
    [`getconf(1P)`](https://man.archlinux.org/man/getconf.1p.en)

## Signals and `wait`

An interesting POSIX behaviour I noticed [from the
docs](https://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html#tag_18_11):

> When the shell is waiting, by means of the wait utility, for asynchronous
> commands to complete, the reception of a signal for which a trap has been set
> shall cause the wait utility to return immediately with an exit status \>128,
> immediately after which the trap associated with that signal shall be taken.

So the `trap` on the first line below means sending `SIGINT` to the program will
cause `sleep` to exit:

``` sh
trap : SIGINT

echo "I am $$"

echo "sleeping for a long time"
sleep 1000 &
wait
echo "waking"
```
