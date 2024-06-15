# Docker build secrets

Some notes on extracting secrets used in Docker build without secret mounts etc.
even for the case when the secret was used in the build stage of a multi-stage
build.

## With `buildkit`

``` console
$ DOCKER_BUILDKIT=1 docker build \
    --build-arg GITHUB_TOKEN=my_token \
    --progress plain \
    .
#0 building with "default" instance using docker driver

#1 [internal] load build definition from Dockerfile
#1 transferring dockerfile: 353B done
#1 DONE 0.0s

#2 [internal] load metadata for docker.io/library/alpine:latest
#2 DONE 0.0s

#3 [internal] load metadata for docker.io/library/golang:1.22-alpine
#3 DONE 0.0s

#4 [internal] load .dockerignore
#4 transferring context: 2B done
#4 DONE 0.0s

#5 [build 1/5] FROM docker.io/library/golang:1.22-alpine
#5 CACHED

#6 [stage-1 1/2] FROM docker.io/library/alpine:latest
#6 CACHED

#7 [internal] load build context
#7 transferring context: 112B done
#7 DONE 0.0s

#8 [build 2/5] RUN     apk add --quiet --no-cache git     && git config --global url."https://my_token@github.com/".insteadOf "https://github.com/"
#8 DONE 2.2s

#9 [build 3/5] WORKDIR /src
#9 DONE 0.0s

#10 [build 4/5] ADD . .
#10 DONE 0.1s

#11 [build 5/5] RUN go build -o app .
#11 DONE 4.7s

#12 [stage-1 2/2] COPY --from=build /src/app /bin/app
#12 DONE 0.1s

#13 exporting to image
#13 exporting layers
#13 exporting layers 0.7s done
#13 writing image sha256:c05f1807fbba6f9409eb40fe99d2a22ecdffa38959d87e8a9fc8cacd88d33700 done
#13 DONE 0.7s
```

The secret will then be present in some parts of the build environment, e.g. in
the [attestations](https://docs.docker.com/build/attestations/slsa-provenance/)
that describe the build config:

``` console
grep \
    --recursive my_token \
    -- "$(docker info --format '{{ .DockerRootDir }}')/buildkit/content/blobs" 2>/dev/null
/var/lib/docker/buildkit/content/blobs/sha256/286293ddd2b19512c92e300530efb48d8de1130eef46fae055bcbaa7dec38827:  "Name": "[build 2/5] RUN     apk add --quiet --no-cache git     \u0026\u0026 git config --global url.\"https://my_token@github.com/\".insteadOf \"https://github.com/\"",
/var/lib/docker/buildkit/content/blobs/sha256/286293ddd2b19512c92e300530efb48d8de1130eef46fae055bcbaa7dec38827:        "Value": "/usr/lib/docker/cli-plugins/docker-buildx buildx build --build-arg GITHUB_TOKEN=my_token --progress plain ."
/var/lib/docker/buildkit/content/blobs/sha256/ee991a2778861a434a8dceb7545ceab175d36b0d85a3f081b5b7aa6414ce17e7:        "build-arg:GITHUB_TOKEN": "my_token"
/var/lib/docker/buildkit/content/blobs/sha256/ee991a2778861a434a8dceb7545ceab175d36b0d85a3f081b5b7aa6414ce17e7:                  "GITHUB_TOKEN=my_token"
/var/lib/docker/buildkit/content/blobs/sha256/ee991a2778861a434a8dceb7545ceab175d36b0d85a3f081b5b7aa6414ce17e7:                  "GITHUB_TOKEN=my_token"
```

Though I'm not sure how to inspect the cache used by `buildkit` to extract the
actual raw `/root/.gitconfig` contents.

## Without `buildkit`

``` console
$ DOCKER_BUILDKIT=0 docker build \
    --build-arg GITHUB_TOKEN=my_token \
    .
Sending build context to Docker daemon   5.12kB
Step 1/9 : FROM golang:1.22-alpine AS build
 ---> 1c62267f65a3
Step 2/9 : ARG GITHUB_TOKEN
 ---> Running in 4ed00fb809bb
 ---> Removed intermediate container 4ed00fb809bb
 ---> f8bc7d1a5c08
Step 3/9 : RUN     apk add --quiet --no-cache git     && git config --global url."https://${GITHUB_TOKEN}@github.com/".insteadOf "https://github.com/"
 ---> Running in 5231e83f42d3
 ---> Removed intermediate container 5231e83f42d3
 ---> 63ffdc4ebcc4
Step 4/9 : WORKDIR /src
 ---> Running in 26d3ea252940
 ---> Removed intermediate container 26d3ea252940
 ---> fc6d3bcd2212
Step 5/9 : ADD . .
 ---> 5fd6126083a2
Step 6/9 : RUN go build -o app .
 ---> Running in 6653da956de1
 ---> Removed intermediate container 6653da956de1
 ---> f18832ac9500
Step 7/9 : FROM alpine:latest
 ---> 1d34ffeaf190
Step 8/9 : COPY --from=build /src/app /bin/app
 ---> 307d054bbfc5
Step 9/9 : CMD ["/bin/app"]
 ---> Running in 794b24146d08
 ---> Removed intermediate container 794b24146d08
 ---> 81de4d1f2b2d
Successfully built 81de4d1f2b2d
Successfully tagged without-buildkit:latest
```

The secret can than be taken by inspecting build layer after it was written to
git's config:

``` console
$ docker run --interactive 63ffdc4ebcc4 cat /root/.gitconfig
[url "https://my_secret@github.com/"]
	insteadOf = https://github.com/
```
