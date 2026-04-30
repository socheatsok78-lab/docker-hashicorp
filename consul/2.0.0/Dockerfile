ARG CONSUL_VERSION=2.0.0-rc1
ARG GO_VERSION=1.26
ARG NODE_VERSION=20

ARG GO_DISCOVER_REPO=github.com/socheatsok78-lab/go-discover
ARG GO_DISCOVER_VERSION=go-netaddrs-v1.2.0
ARG GITHUB_REPOSITORY_OWNER=socheatsok78-lab

FROM --platform=$BUILDPLATFORM golang:${GO_VERSION}-alpine AS builder-golang
RUN apk add --no-cache bash curl git patch

FROM --platform=$BUILDPLATFORM node:${NODE_VERSION}-alpine AS builder-node
RUN apk add --no-cache bash curl git patch make go
RUN npm install -g corepack && corepack disable && corepack enable

# Stage 0: Clone the consul repository
FROM --platform=$BUILDPLATFORM builder-golang AS stage0
ARG CONSUL_VERSION
RUN git clone --depth=1 --branch=v${CONSUL_VERSION} --single-branch https://github.com/hashicorp/consul.git /consul

# Stage 1: Build the UI
FROM --platform=$BUILDPLATFORM builder-node AS stage1
ARG CONSUL_VERSION
WORKDIR /consul
RUN --mount=type=bind,from=stage0,source=/consul,target=/consul,rw \
<<EOF
    set -ex
    make ui-regen
    cp -a /consul/agent/uiserver /uiserver
EOF

# Stage 2: Build the consul binary
FROM --platform=$BUILDPLATFORM builder-golang AS stage2

# Build the consul binary
ARG TARGETARCH
ARG CONSUL_VERSION
ARG GO_VERSION
ARG GO_DISCOVER_REPO
ARG GO_DISCOVER_VERSION
ARG GITHUB_REPOSITORY_OWNER
WORKDIR /consul
RUN --mount=type=bind,from=stage0,source=/consul,target=/consul,rw \
    --mount=type=bind,from=stage1,source=/uiserver,target=/consul/agent/uiserver \
    --mount=type=cache,sharing=locked,id=go-${GO_VERSION}/go/pkg/mod,target=/go/pkg/mod \
    --mount=type=tmpfs,target=/root/.cache/go-build \
<<EOF
    set -ex

    # Replace the go-discover dependency with the socheatsok78-lab version
    go mod edit -replace github.com/hashicorp/go-discover=${GO_DISCOVER_REPO}@${GO_DISCOVER_VERSION}

    go mod tidy
    # (cd api && go mod tidy)
    # (cd sdk && go mod tidy)

    GIT_IMPORT="github.com/hashicorp/consul/version"
    GIT_COMMIT=$(git rev-parse --short HEAD)
    GIT_COMMIT_YEAR=$(git show -s --format=%cd --date=format:%Y HEAD)
    GIT_DIRTY=$(test -n "`git status --porcelain`" && echo "+CHANGES" || true)
    GIT_DIRTY=${GIT_DIRTY}${GITHUB_REPOSITORY_OWNER:+"+${GITHUB_REPOSITORY_OWNER}"}
    DATE_FORMAT="%Y-%m-%dT%H:%M:%SZ"
    GIT_DATE=$(date -u +${DATE_FORMAT})

    GOTAGS="consul ui"
    GOLDFLAGS="-w -s"
    GOLDFLAGS="${GOLDFLAGS} -X ${GIT_IMPORT}.GitCommit=${GIT_COMMIT}${GIT_DIRTY}"
    GOLDFLAGS="${GOLDFLAGS} -X ${GIT_IMPORT}.BuildDate=${GIT_DATE}"

    CGO_ENABLED=0 GOOS=linux GOARCH=${TARGETARCH} go build -o /usr/local/bin/consul -tags "${GOTAGS}" -ldflags "${GOLDFLAGS}" .
EOF

# Final stage
FROM consul
COPY --link --from=stage2 /usr/local/bin/consul /bin/consul
