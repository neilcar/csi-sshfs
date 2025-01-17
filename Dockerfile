FROM --platform=$BUILDPLATFORM golang:1.16-alpine3.14 AS  build-env
RUN apk add --no-cache git

ENV CGO_ENABLED=0, GO111MODULE=on

WORKDIR /go/src/

ADD . /go/src/

ARG TARGETOS TARGETARCH

RUN GOOS=$TARGETOS GOARCH=$TARGETARCH go mod download
RUN GOOS=$TARGETOS GOARCH=$TARGETARCH export BUILD_TIME=`date -R` && \
    export VERSION=`cat version.txt 2&> /dev/null` && \
    apk add --no-cache gcc libc-dev && \
    go build -o /csi-sshfs -ldflags "-X 'pkg/sshfs.BuildTime=${BUILD_TIME}' -X 'pkg/sshfs.Version=${VERSION}'" cmd/csi-sshfs

FROM alpine:3.16

RUN apk add --no-cache ca-certificates sshfs findmnt

COPY --from=build-env /csi-sshfs /bin/csi-sshfs

ENTRYPOINT ["/bin/csi-sshfs"]
CMD [""]
