# Go Docker project

A simple Go project to demonstrate some principles when building Go projects
with Docker. There are two Dockerfiles each demonstrating how to inject secrets
via secret mounts and avoid including them in the build history

## With SSH key

See `ssh.dockerfile`, to build you need to provide an SSH key:

``` console
$ docker build \
    --file ssh.dockerfile \
    --secret id=ssh-key,src=/path/to/ssh-key \
    .
```

## With GitHub token

See `token.dockerfile`, to build you need a GitHub token with permissions to
clone any repos:

``` console
$ GITHUB_TOKEN=<token-goes-here> docker build \
    --file token.dockerfile \
    --secret id=github_token,env=GITHUB_TOKEN \
    .
```
