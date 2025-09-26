ARG VAULT_VERSION=1.20.4
ARG GO_VERSION=1.24.6
ARG NODE_VERSION=20

# Stage 0: Clone the Vault repository
ARG ALPINE_VERSION=3.13
FROM --platform=$BUILDPLATFORM alpine:${ALPINE_VERSION} AS stage0
RUN apk add --no-cache git
ARG VAULT_VERSION
RUN git clone --depth=1 --branch=v${VAULT_VERSION} --single-branch https://github.com/hashicorp/vault.git /vault

# Stage 1: Build the UI
FROM --platform=$BUILDPLATFORM node:${NODE_VERSION}-alpine AS stage1
RUN apk add --no-cache git patch make
RUN npm install -g corepack && corepack disable && corepack enable
COPY --link --from=stage0 /vault /vault
WORKDIR /vault
ENV YARN_CACHE_FOLDER=/usr/local/share/.cache/yarn
RUN --mount=type=cache,target=/root/.yarn/ \
    --mount=type=cache,target=/root/.cache/yarn \
    --mount=type=cache,target=/usr/local/share/.cache/yarn \
<<EOF
    make ember-dist
EOF

# Stage 2: Build the Vault binary
FROM --platform=$BUILDPLATFORM golang:${GO_VERSION}-alpine AS stage2
RUN apk add --no-cache bash git patch

# Copy the Vault source code from the previous stage
COPY --link --from=stage0 /vault /vault
COPY --link --from=stage1 /vault/http/web_ui/ /vault/http/web_ui/
WORKDIR /vault

# Replace the go-discover dependency with the socheatsok78-lab version
RUN echo "replace github.com/hashicorp/go-discover => github.com/socheatsok78-lab/go-discover go-netaddrs" >> go.mod
RUN echo "replace github.com/hashicorp/go-cmp => github.com/google/go-cmp v0.7.0" >> go.mod

# Build the Vault binary
ARG TARGETARCH
ARG GITHUB_REPOSITORY_OWNER=socheatsok78-lab
RUN --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
<<EOF
    go mod tidy
    # (cd api && go mod tidy)
    # (cd sdk && go mod tidy)

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
    for GOARCH in amd64 arm64; do
        mkdir -p ./pkg/bin/linux_${GOARCH}
        (set -x; CGO_ENABLED=0 GOOS=linux GOARCH=${GOARCH} go build -o ./pkg/bin/linux_${GOARCH} -tags "${GOTAGS}" -ldflags "${GOLDFLAGS}" .)
    done
EOF

# Final stage
FROM hashicorp/vault:${VAULT_VERSION}
ARG TARGETARCH
COPY --from=stage2 /vault/pkg/bin/linux_${TARGETARCH}/vault /bin/vault
