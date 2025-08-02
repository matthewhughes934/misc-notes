# Idempotent File Write

## The bug

Debugging an issue that came up at work where, under `bash`:

    $ echo 'some content' > important_file.txt

Would leave `important_file.txt` truncated.

## The background

We expected:

  - the shell to call `openat(AT_FDCWD, "important_file.txt",
    O_WRONLY|O_CREAT|O_TRUNC, 0666)`
  - `echo` to call `write` on the returned file handle

So, upon successful `open` the file will be truncated, then if `write` fails it
will be left that way. One fail this can fail is if `openat` returns ok, but
`write` returns `ENOSPC`. If this were the only process writing to disk we
wouldn't see an issue, since:

  - `open` would truncate the file, freeing at least one block on disk
  - `write` would then be able to write at least one block

Though the above might leave us in the situation of only a partial write having
completed. However, if there are other process writing to disk we can quickly
hit a race condition:

  - `openat` returns ok and truncates the file, at least one block on disk is
    available
  - Some other process manages to write at least one block to some other file
    (e.g. some process writing to a system log)
  - The `write` call fails as there's no space left.

Demonstrating the race-condition with Docker, create a `tmpfs` with just a small
amount of space so we can easily test:

    docker run --rm --tty --interactive --tmpfs /small_mount:size=1m alpine:latest

``` console
$ cd /small_maount
# fill up all but one block
$ dd if=/dev/urandom of=/small_mount/big_file bs=4K count=255
# fill the last block
$ echo 'important content' > important_file.txt
# spin up some processes to write to other files
$ while : ; do for i in seq 1 20; do echo "some log" > logfile_$i.txt 2>/dev/null & done; done &
# keep trying o write to our file until we fail
$ i=0; while : ; do echo "attempt $i"; echo 'new content' > important_file.txt || break;  i=`expr $i + 1`; done
```

## The solution

Make the write idempotent:

  - Write the content you want to some temporary file
  - `mv "$tmp_file" "$dest"`

`mv` should use the `rename` syscall [which will
ensure](https://pubs.opengroup.org/onlinepubs/9699919799/functions/rename.html):

> neither the file named by old nor the file named by new shall be changed or
> created

You should, of course, check the return value of `cp` before trying to `move`
(or just set `errexit`)
