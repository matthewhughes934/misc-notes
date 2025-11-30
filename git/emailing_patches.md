# Emailing Patches

Via `neomutt`.

Assuming you're on a branch off `master`, manually invoking `neomutt`:

``` console
# add a description, used as the cover letter (first email)
$ git branch --edit-description
# add --thread so the emails will be threaded together
$ git format-patch --cover-letter --cover-from-description=subject --thread --to git@vger.kernel.org master..
# send emails
$ for p in *.patch; do neomutt -H "$p"; done
```

Or, configuring [`git send-email`](git-scm.com/docs/git-send-email) to use
`neomutt`:

``` console
# sendmailCmd will invoke the command with the '-i' flag (expected for # `sendmail`),
# and passes the email contents via stdin.
# The `-i` in neomutt isn't the same as `sendmail` so we want to ignore it, so
# append 'false' command to swallow this flag while still failling if neomutt does
$ git config sendemail.sendmailCmd 'neomutt -H - || false'
# send-mail will handling threading for us, so no need to add the flag when
# generating patches, we'll also move '--to' to `send-email`
$ git format-patch --cover-letter --cover-from-description=subject master..
$ git send-email --to git@vger.kernel.org *.patch
```

Note: you might want to pass `--stdout` to `format-patch` so you can review the
details before sending.
