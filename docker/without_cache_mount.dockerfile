# syntax=docker/dockerfile:1.2
FROM busybox

RUN mkdir /tmp/data && \
    dd if=/dev/urandom bs=1024 count=5000 of=/tmp/data/file
