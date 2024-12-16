# Docker best practices

## `SHELL` instructions

All stages in a dockerfile should contain a `SHELL` specification:

``` dockerfile
SHELL ["/bin/bash", "-o", "errexit", "-o", "nounset", "-o", "pipefail", "-c"]
```

See the [bash
manual](https://www.gnu.org/software/bash/manual/html_node/The-Set-Builtin.html#The-Set-Builtin)
for an explanation of what these `-o` flags control. See [this blog
post](https://coderwall.com/p/fkfaqq/safer-bash-scripts-with-set-euxo-pipefail)
for more details on how this is helpful.

## `RUN` instruction separator

Commands should be separated with `&&` rather than `;`. Even though with the
shell invocation above `;` is equivalent to (and shorter than) `&&` this is
helpful to make it a bit more explicit, it also helps if people copy part of a
dockerfile but don't include the shell invocation above.

Bad:

``` dockerfile
RUN python -m venv /path/to/venv; \
    /path/to/venv/pip install setuptools wheel
```

Good:

``` dockerfile
RUN python -m venv /path/to/venv && \
    /path/to/venv/pip install setuptools wheel
```

## `RUN` use basic text output

Many programs that you may want to run when building a docker image include
fancy (colourful, emojis, etc.) output that can be nice to view from your
terminal emulator when running things locally, but can be painful to be debug in
CI (such as `pip`). I find it most helpful to make these commands print
information in as basic a format as possible.

Bad:

``` dockerfile
RUN pip install setuptools wheel
```

Good:

``` dockerfile
RUN pip install --progress-bar off setuptools wheel
```

## `RUN` avoid adding caches into your layers

Many programs that install software will use a cache to speed up future
installs. This is not too helpful when building docker images since:

1.  The caches cannot be reused between runs
2.  The caches add size to your final docker image

Many of these commands come with options to disable caching, which should be
used.

Bad:

``` dockerfile
RUN pip install poetry && \
    poetry install
```

Good:

``` dockerfile
# --no-cache option for poetry added in 1.2.0
RUN pip install --no-cache poetry>=1.2.0 && \
    poetry install --no-cache
```

## `.dockerignore`

It's very easy to add additional files to Docker without realising it. This is
because, unlike ignoring things in `git` where a missing file will show in the
output of `git diff`, the consequences of including a file vary from

  - Best case, does nothing but maybe increases the size of your image
  - Worst case, causes some critical information leak, like [this PyPI
    incident](https://blog.pypi.org/posts/2024-07-08-incident-report-leaked-admin-personal-access-token/)
    For this reason, I recommend a *restrictive* `.dockerignore`, that is, it
    ignores everything by default, files that *should* be included are added as
    exceptions, e.g. for a simple Go app:

<!-- end list -->

``` ignore
# ignore everything
*

# explicitly include bits we need
!go.sum
!go.mod
!*.go
```
