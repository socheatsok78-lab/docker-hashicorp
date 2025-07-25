ARG GO_VERSION=1.23.8

FROM --platform=$BUILDPLATFORM golang:${GO_VERSION}-alpine AS build
ADD https://github.com/socheatsok78/go-discover-dockerswarm.git#main /go-discover-dockerswarm
WORKDIR /go-discover-dockerswarm/cmd
RUN go build -ldflags "-w -s" -o /usr/local/bin/discover-dockerswarm . \
    && chmod u+s /usr/local/bin/discover-dockerswarm

FROM scratch
COPY --from=build --link /usr/local/bin/discover-dockerswarm /usr/local/bin/discover-dockerswarm
ADD rootfs /
