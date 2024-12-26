# Git Ignore

## Keep only project specific bits in `.gitignore`

Only files created by the project, or some tool that the project uses directly,
should be included in the project's `.gitignore`. For example:

  - Build artefacts e.g. binaries for compiled languages, or `dist/` directories
    for Python
  - Tool specific files like cache files (e.g `.mypy_cache`) or files generated
    by tools like `.coverage` files.

Things that should *not* be included:

  - Editor/IDE specific files like `*.swp` or `.idea/` directories
  - OS specific files like `.DS_Store` on MacOS

Files like these should be ignored by the user in their
[`core.excludesFile`](https://git-scm.com/docs/git-config#Documentation/git-config.txt-coreexcludesFile)

For example, for a Python project using `mypy`, `pytest`, `tox`, and `coverage`
the project's `.gitignore` might look like:

``` ignore
*.py[co]

# Testing/linting
/.mypy_cache
/.pytest_cache
/.tox/
/.coverage

# Build artefacts
dist/
*.egg-info/
*.egg
build/
```

Whereas a user specific ignore (`core.excludesFile`) might look like:

``` ignore
# Vim
*.sess
*.sw?
.vimrc

# ctags and friends
*.ctags
tags

.venv*/
# used by pyenv
.python-version
```
