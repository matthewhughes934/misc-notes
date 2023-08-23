FROM golang:1.21-alpine AS build

RUN \
    apk add --no-cache \
        git \
        openssh-client \
    && \
    # configure Git to use SSH and never HTTPS for each GitHub, GitLab, and BitBucket
    # and add the fingerprints. You could also maintain yourself the fingerprints
    # and COPY them in
    git config --global url.ssh://git@github.com/.insteadOf https://github.com/ && \
    git config --global url.ssh://git@bitbucket.org/.insteadOf https://bitbucket.org/ && \
    git config --global url.ssh://git@gitlab.com/.insteadOf https://gitlab.com/ && \
    mkdir -p /root/.ssh && \
    ssh-keyscan github.com gitlab.com bitbucket.org >> /root/.ssh/known_hosts

WORKDIR /build
# COPY up only what we need to download dependencies
# this allows us to store in the downloaded dependencies in Docker's layer cache
# and only re-download when we chage one of thse two files
COPY go.mod go.sum .
# mount the SSH key as a secret, and have git use it via GIT_SSH_COMMAND
# use a cache mount (https://docs.docker.com/build/guide/mounts/#add-a-cache-mount)
# for GOMODCACHE and GOCACHE
# "GOPRIVATE='github.com/spf13/*'" is just used as an example (it's publicly available)
# so we force Go to fetch it via Git
RUN \
    --mount=type=secret,id=ssh-key \
    --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build/ \
    GOPRIVATE='github.com/spf13/*' GIT_SSH_COMMAND="ssh -i /run/secrets/ssh-key" go mod download

# COPY everyting else (i.e. our .go files) up...
COPY . .
# and build
# again, use a cache so we can re-use compiled dependencies even after invalidating
# the layer cache
# you can further reduce the size of your binary by stripping debug info
# i.e. adding "-ldflags='-s -w'" to 'go build' (https://pkg.go.dev/cmd/link#hdr-Command_Line)
# but if you want to debug the running binary it will be simpler if these are left in
RUN \
    --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build/ \
    go build -o hello ./

# Use a small final image.
# 'scratch' would also work, but there's no extras provided, not even a shell
# which can make debugging a nuissance
FROM alpine:3.18

COPY --from=build /build/hello /bin/hello
ENTRYPOINT [ "/bin/hello" ]
