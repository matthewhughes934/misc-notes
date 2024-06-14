FROM golang:1.22-alpine AS build

ARG GITHUB_TOKEN

RUN \
    apk add --quiet --no-cache git \
    && git config --global url."https://${GITHUB_TOKEN}@github.com/".insteadOf "https://github.com/"

WORKDIR /src
ADD . .
RUN go build -o app .

FROM alpine:latest

COPY --from=build /src/app /bin/app
CMD ["/bin/app"]
