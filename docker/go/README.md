# Go Docker project

A simple Go project to demonstrate some principles when building Go projects
with Docker. It makes use of a SSH key mounted as a secret at build time to
fetch dependencies over Git rather than e.g. injecting a Github user-name and
token into the build image which will result in those secrets being exposed in
the image's history.

To build you need to provide an SSH key:

``` console
$ docker build --secret id=ssh-key,src=/path/to/ssh-key .
```
