# `git`

## Not sufficient to unset `rerere.enabled`

I was playing around [this config
option](https://git-scm.com/docs/git-config#Documentation/git-config.txt-rerereenabled)
and was repeating a merge, at some point I realise a solution I'd repeated was
not the desired one so I tried unsetting this via `got git config unset --local
rerere.enabled`, but on my next merge I noticed a previous solution was applied.
This behaviour is clearly documented:

> By default, git-rerere\[1\] is enabled if there is an rr-cache directory under
> the $GIT\_DIR, e.g. if "rerere" was previously used in the repository.

But still came as a surprised to me (I'm used to `git` configurations defaulting
to false/off). The solution was to set `rerere.enabled` to `false`.

I'm guessing it's for historical reasons, as it seems originally detection of
this feature was based purely on the existence of the `rr-cache` directory, and
so I assume it was kept this way for backwards compatibility (see [this
commit](https://git.kernel.org/pub/scm/git/git.git/commit/?id=b4372ef136b0a5a2c1dbd88a11dd72b478d0e0a5))
