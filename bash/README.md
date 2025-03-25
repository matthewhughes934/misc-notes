# Bash

## `~` in `PATH`

Per the [tilde expansion
docs](https://www.gnu.org/software/bash/manual/html_node/Tilde-Expansion.html)
`bash` will expand a `~` in the `PATH` var, however, is is not particularly
portable, e.g. it is disabled in POSIX mode (see section 19
[here](https://www.gnu.org/software/bash/manual/html_node/Bash-POSIX-Mode.html)).
So avoid doing this
