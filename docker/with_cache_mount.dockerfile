# syntax=docker/dockerfile:1.2
FROM busybox

RUN --mount=type=cache,target=/tmp/data \
  dd if=/dev/urandom bs=1024 count=5000 of=/tmp/data/file
