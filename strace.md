# Strace

Some options I've found useful when running `strace`

  - Don't show any signals: `strace -e 'signal=!all'`
  - Show more details of args etc.: `strace -s 400`
