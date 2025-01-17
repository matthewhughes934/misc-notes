FROM golang:1.21-alpine AS build

# install git and configure a custom credential helper
# https://git-scm.com/docs/gitcredentials#_custom_helpers
# to load the token from a secret mount when needed
RUN apk add --no-cache git && \
    git config --global \
        'credential.https://github.com.helper' \
        '!f() { [ "$1" = "get" ] && echo -e "username=user\npassword="$(cat /run/secrets/github_token)"; }; f'

WORKDIR /build
# COPY up only what we need to download dependencies
# this allows us to store in the downloaded dependencies in Docker's layer cache
# and only re-download when we chage one of thse two files
COPY go.mod go.sum .
# mount the token key as a secret, git will load it from the configuration above
# for GOMODCACHE and GOCACHE
# "GOPRIVATE='github.com/spf13/*'" is just used as an example (it's publicly available)
# so we force Go to fetch it via Git
RUN \
    --mount=type=secret,id=github_token \
    --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build/ \
    GOPRIVATE='github.com/spf13/*' \
    go mod download

# COPY everyting else (i.e. our .go files) up...
COPY . .
# and build
# again, use a cache so we can re-use compiled dependencies even after invalidating
# the layer cache
# you can further reduce the size of your binary by stripping debug info
# i.e. adding "-ldflags='-s -w'" to 'go build' (https://pkg.go.dev/cmd/link#hdr-Command_Line)
# but if you want to debug the running binary it will be simpler if these are left in
# again mount the tokn as a secret, in case we need to download some extra dependencies a build time
RUN \
    --mount=type=secret,id=github_token \
    --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build/ \
    go build -o hello ./

# Use a small final image.
# 'scratch' would also work, but there's no extras provided, not even a shell
# which can make debugging a nuissance
FROM alpine:3.18

# create a non-root user to run our application
RUN \
    addgroup --system user && \
    adduser --ingroup user --disabled-password --no-create-home --system user

COPY --chown=user:user --from=build /build/hello /bin/hello
USER user
ENTRYPOINT [ "/bin/hello" ]
