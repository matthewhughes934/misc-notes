# Docker

General notes about docker

## `RUN --mount=type=cache`

See [some
docs](https://github.com/moby/buildkit/blob/47e953b294d4a5b4a1dfd68aec788c3642dbf5a7/frontend/dockerfile/docs/reference.md#run---mounttypecache)

These can be very useful in speeding up local build caches. For example, if you
point `pip`'s `--cache-dir` at this mount then you can speed up future local
builds. I'm not sure if this can be used to improve CI builds where the context
is blow away each time though.

Importantly, the files stored in these mounts don't contribute to overall image
size. For example, this directory contains two dockerfiles that both just build
5MB files however one of them stores this file in the mount cache and the other
just stores it in the image:

``` console
$ DOCKER_BUILDKIT=1 docker build --tag with-cache --file with_cache_mount.dockerfile .
$ DOCKER_BUILDKIT=1 docker build --tag without-cache --file without_cache_mount.dockerfile .
$ docker images --format '{{.Size}}' with-cache
1.24MB
$ docker images --format '{{.Size}}' without-cache
6.36MB
```
