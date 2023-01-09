# Strace

Some options I've found useful when running `strace`

  - Don't show any signals: `strace -e 'signal=!all'`
  - Show more details of args etc.: `strace -s 400`

For programs that do a lot of `fork/clone`ing you can combine the logs nicely
using `strace-log-merge`:

``` console
$ strace --absolute-timestamps --output-separately --follow-forks --output strace.log --string-limit=1000 -- some-prog args go here
$ strace-log-merge strace.log > merged.log
```
