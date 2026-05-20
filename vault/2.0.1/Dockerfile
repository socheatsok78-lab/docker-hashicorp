ARG VAULT_VERSION=2.0.1
ARG GO_VERSION=1.26.3
ARG NODE_VERSION=20

ARG GO_DISCOVER_REPO=github.com/socheatsok78-lab/go-discover
ARG GO_DISCOVER_VERSION=go-netaddrs-v1.2.0
ARG GITHUB_REPOSITORY_OWNER=socheatsok78-lab

FROM --platform=$BUILDPLATFORM golang:${GO_VERSION}-alpine AS builder-golang
RUN apk add --no-cache bash curl git patch

FROM --platform=$BUILDPLATFORM node:${NODE_VERSION}-alpine AS builder-node
RUN apk add --no-cache bash curl git patch make go
RUN npm install -g corepack && corepack disable && corepack enable

# Stage 0: Clone the repository
FROM --platform=$BUILDPLATFORM builder-golang AS stage0
ARG VAULT_VERSION
RUN git clone --depth=1 --branch=v${VAULT_VERSION} --single-branch https://github.com/hashicorp/vault.git /vault

# Stage 1: Build the UI
FROM --platform=$BUILDPLATFORM builder-node AS stage1
ARG VAULT_VERSION
WORKDIR /vault
RUN --mount=type=bind,from=stage0,source=/vault,target=/vault,rw \
<<EOF
    set -ex
    make ember-dist
    cp -a /vault/http/web_ui/ /web_ui
EOF

# Stage 2: Build the binary
FROM --platform=$BUILDPLATFORM builder-golang AS stage2

ARG TARGETARCH
ARG VAULT_VERSION
ARG GO_VERSION
ARG GO_DISCOVER_REPO
ARG GO_DISCOVER_VERSION
ARG GITHUB_REPOSITORY_OWNER
WORKDIR /vault
RUN --mount=type=bind,from=stage0,source=/vault,target=/vault,rw \
    --mount=type=bind,from=stage1,source=/web_ui,target=/vault/http/web_ui/ \
    --mount=type=cache,sharing=locked,id=go-${GO_VERSION}/pkg/mod,target=/go/pkg/mod \
    --mount=type=tmpfs,target=/root/.cache/go-build \
<<EOF
    set -ex

    # Replace the go-discover dependency with the socheatsok78-lab version
    go mod edit -replace github.com/hashicorp/go-discover=${GO_DISCOVER_REPO}@${GO_DISCOVER_VERSION}

    go mod tidy
    (set -x; cd api && go mod tidy)
    (set -x; cd sdk && go mod tidy)

    GIT_IMPORT="github.com/hashicorp/vault/version"
    GIT_COMMIT=$(git rev-parse --short HEAD)
    GIT_COMMIT_YEAR=$(git show -s --format=%cd --date=format:%Y HEAD)
    GIT_DIRTY=$(test -n "`git status --porcelain`" && echo "+CHANGES" || true)
    GIT_DIRTY=${GIT_DIRTY}${GITHUB_REPOSITORY_OWNER:+"+${GITHUB_REPOSITORY_OWNER}"}
    DATE_FORMAT="%Y-%m-%dT%H:%M:%SZ"
    GIT_DATE=$(date -u +${DATE_FORMAT})

    GOTAGS="vault ui"
    GOLDFLAGS="-w -s"
    GOLDFLAGS="${GOLDFLAGS} -X ${GIT_IMPORT}.GitCommit=${GIT_COMMIT}${GIT_DIRTY}"
    GOLDFLAGS="${GOLDFLAGS} -X ${GIT_IMPORT}.BuildDate=${GIT_DATE}"
    
    CGO_ENABLED=0 GOOS=linux GOARCH=${TARGETARCH} go build -o /usr/local/bin/vault -tags "${GOTAGS}" -ldflags "${GOLDFLAGS}" .
EOF

# Stage 3: Final stage
FROM vault
COPY --link --from=stage2 /usr/local/bin/vault /bin/vault
