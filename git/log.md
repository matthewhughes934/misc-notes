# Git log

## Tracing function history

This is what `git log -L:<funcname>:<filename>` is for
[docs](https://git-scm.com/docs/git-log#Documentation/git-log.txt--Lltfuncnamegtltfilegt)

However, there are some quirks around this. Firstly, by default there is not
[`diff`
attribute](https://git-scm.com/docs/gitattributes#_setting_the_internal_diff_algorithm)
associate with file types. This means when trying to find a hunk header `git`
will simply iterate through the [built-in diff
drivers](https://git.kernel.org/pub/scm/git/git.git/tree/userdiff.c?h=6249de53a3016e33dd32ef83620068f19a4e08af#n42)
which generally works fine, but does mean you can confuse things. Consider
`example.py` in this directory which contains some Perl code in comments inside
Python (the built-in diff drivers are sorted alphabetically, so Perl will be
before Python). Without any diff association we can see `git` will match on the
Perl functions:

``` console
$ git log --format='' --patch -L:my_func:./git/example.py

diff --git a/git/example.py b/git/example.py
--- /dev/null
+++ b/git/example.py
@@ -0,0 +5,6 @@
+sub my_func {
+    my ($name) = @_
+    
+    # do stuff with $name...
+}
+
```

By setting diff association (i.e. adding `*.py diff=python` in `.gitattributes`)
the correct hunk header is found:

``` console
$ git log --format='' --patch -L:my_func:./git/example.py

diff --git a/git/example.py b/git/example.py
--- /dev/null
+++ b/git/example.py
@@ -0,0 +14,4 @@
+    def my_func(self, name):
+        # do stuff with name...
+        ...
+
```

More importantly, this all means that *unless* there's a default diff drive for
your language, this simply won't work out of the box, for example with
TypeScript:

``` console
$ git log -L:myFunc:git/example.ts
fatal: -L parameter 'myFunc' starting at line 1: no match
```

To get this working as expected we just need to follow [the
docs](https://git-scm.com/docs/gitattributes#_defining_a_custom_hunk_header).
Step 1, add a new diff type (in this case, with a quick and dirty regex) to
Git's config:

``` gitconfig
[diff "typescript"]
	xfuncname = "^[\t ]*(function|static|constructor|public|private|protected)? +[a-zA-Z0-9_-]+\\(.*$"
```

and step 2, associate the corresponding files with the differ:

``` gitattributes
*ts diff=typescript
```

Now things work:

``` console
$ git log --format='' -L:someStaticFunc:git/example.ts

diff --git a/git/example.ts b/git/example.ts
--- /dev/null
+++ b/git/example.ts
@@ -0,0 +6,2 @@
+    static someStaticFunc(name: string) {}
+
$ git log --format='' -L:myFunc:git/example.ts

diff --git a/git/example.ts b/git/example.ts
--- /dev/null
+++ b/git/example.ts
@@ -0,0 +8,2 @@
+    myFunc(name: string) {}
+}
```

## Tracing Go method history

It is common in Go that the same method will be implemented in different structs
in a single file, but since `git log -L:funcName:path/to/file.go` will track the
history of the *first matching function* then things need to be more specific.

Take for example [`src/archive/tar/reader.go` in
Golang](https://go.googlesource.com/go/+/b57a544f99e5c4166468737942b7af5acb5936b3/src/archive/tar/reader.go),
there are several structs with `Read` implemented:

``` console
$ git grep --count '^func.*Read' src/archive/tar/reader.go
src/archive/tar/reader.go:25
```

Per [the
docs](https://git-scm.com/docs/git-log#Documentation/git-log.txt--Lltfuncnamegtltfilegt)
with the `:funcname` format, `funcname` is actually just a regular expression,
so we can add some more context to specify the exact method we're interested in,
e.g.:

``` console
git log -L:'regFileReader) Read':src/archive/tar/reader.go
```
