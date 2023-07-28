# Checkout Speed

Comparing the speed of various checkout methods, using
<https://github.com/chromium/chromium> as an example

## Full Clone

``` console
$ time git clone https://github.com/chromium/chromium.git full
Cloning into 'full'...
remote: Enumerating objects: 20871564, done.
remote: Counting objects: 100% (8469/8469), done.
remote: Compressing objects: 100% (4828/4828), done.
remote: Total 20871564 (delta 4027), reused 7798 (delta 3392), pack-reused 20863095
Receiving objects: 100% (20871564/20871564), 37.36 GiB | 30.88 MiB/s, done.
Resolving deltas: 100% (16520190/16520190), done.
Updating files: 100% (423574/423574), done.

real	39m31.286s
user	118m27.156s
sys	5m34.390s
```

## Shallow Clone

With a shallow clone we can fetch much less data by requiring only the most
recent commit and not the full history:

``` console
$ time git clone --depth 1 https://github.com/chromium/chromium.git shallow
Cloning into 'shallow'...
remote: Enumerating objects: 426296, done.
remote: Counting objects: 100% (426296/426296), done.
remote: Compressing objects: 100% (295018/295018), done.
remote: Total 426296 (delta 119067), reused 281072 (delta 105514), pack-reused 0
Receiving objects: 100% (426296/426296), 1.15 GiB | 16.56 MiB/s, done.
Resolving deltas: 100% (119067/119067), done.
Updating files: 100% (423576/423576), done.

real	2m24.972s
user	0m45.126s
sys	0m8.128s
```

## Sparse Checkout

We can get a significant speed up if we want to clone but don't need every file
(e.g. if we're just interested in files under `mojo/core`):

``` console
$ time git clone --depth 1 --filter blob:none --no-checkout https://github.com/chromium/chromium.git sparse
Cloning into 'sparse'...
remote: Enumerating objects: 34371, done.
remote: Counting objects: 100% (34371/34371), done.
remote: Compressing objects: 100% (25402/25402), done.
remote: Total 34371 (delta 1474), reused 22844 (delta 1143), pack-reused 0
Receiving objects: 100% (34371/34371), 13.49 MiB | 17.52 MiB/s, done.
Resolving deltas: 100% (1474/1474), done.

real	0m3.090s
user	0m0.455s
sys	0m0.247s
$ cd sparse
$ git sparse-checkout set mojo/core
$ time git checkout main
remote: Enumerating objects: 242, done.
remote: Counting objects: 100% (242/242), done.
remote: Compressing objects: 100% (225/225), done.
remote: Total 242 (delta 24), reused 70 (delta 17), pack-reused 0
Receiving objects: 100% (242/242), 695.02 KiB | 3.68 MiB/s, done.
Resolving deltas: 100% (24/24), done.
Already on 'main'
Your branch is up to date with 'origin/main'.

real	0m1.386s
user	0m0.626s
sys	0m0.056s
```

Taking less than 10 seconds in total, orders of magnitude faster than a shallow
clone.

A note on the args, `--filter=blob:none` means we skip fetching any file
contents until we need them:

> \--filter=\<filter-spec\>
> 
> Use the partial clone feature and request that the server sends a subset of
> reachable objects according to a given object filter. When using --filter, the
> supplied \<filter-spec\> is used for the partial clone filter. For example,
> --filter=blob:none will filter out all blobs (file contents) until needed by
> Git. Also, --filter=blob:limit=\<size\> will filter out all blobs of size at
> least \<size\>. For more details on filter specifications, see the --filter
> option in git-rev-list(1).
