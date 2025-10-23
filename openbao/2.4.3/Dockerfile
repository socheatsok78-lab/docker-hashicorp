ARG VAULT_VERSION=2.4.3
ARG GO_VERSION=1.24.6
ARG NODE_VERSION=20

ARG ALPINE_VERSION=3
ARG DOCKER_CACHE_KEY=openbao
ARG DOCKER_CACHE_PURGE=true

# Stage 0: Clone the Vault repository
FROM --platform=$BUILDPLATFORM alpine:${ALPINE_VERSION} AS stage0
ARG VAULT_VERSION
RUN <<EOT
    apk add --no-cache --virtual .build-deps curl git
    git clone --depth=1 --branch=v${VAULT_VERSION} --single-branch https://github.com/openbao/openbao.git /vault
    apk del .build-deps
EOT

# Stage 1: Build the UI
FROM --platform=$BUILDPLATFORM node:${NODE_VERSION}-alpine AS stage1
RUN npm install -g corepack && corepack disable && corepack enable
COPY --link --from=stage0 /vault /vault
WORKDIR /vault
ENV YARN_CACHE_FOLDER=/usr/local/share/.cache/yarn
ARG VAULT_VERSION
ARG DOCKER_CACHE_KEY
ARG DOCKER_CACHE_PURGE
RUN --mount=type=cache,sharing=locked,id=${DOCKER_CACHE_KEY}/${VAULT_VERSION}/root/.yarn,target=/root/.yarn \
    --mount=type=cache,sharing=locked,id=${DOCKER_CACHE_KEY}/${VAULT_VERSION}/root/.cache/yarn,target=/root/.cache/yarn \
    --mount=type=cache,sharing=locked,id=${DOCKER_CACHE_KEY}/${VAULT_VERSION}/usr/local/share/.cache/yarn,target=/usr/local/share/.cache/yarn \
<<EOF
    apk add --no-cache --virtual .build-deps curl git patch make
    (set -x; make ember-dist)

    # cleanup, if requested
    if [[ "${DOCKER_CACHE_PURGE}" == "true" ]]; then
        rm -rf /vault/ui/node_modules
        rm -rf /root/.yarn/* /root/.cache/yarn/* /usr/local/share/.cache/yarn/*
    fi
    apk del .build-deps
EOF

# Stage 2: Build the Vault binary
FROM --platform=$BUILDPLATFORM golang:${GO_VERSION}-alpine AS stage2

# Copy the Vault source code from the previous stage
COPY --link --from=stage0 /vault /vault
COPY --link --from=stage1 /vault/http/web_ui/ /vault/http/web_ui/
WORKDIR /vault

# Replace dependencies with alternative forks or versions
RUN echo "replace github.com/hashicorp/go-discover => github.com/socheatsok78-lab/go-discover go-netaddrs" >> go.mod

# Build the Vault binary
ARG TARGETARCH
ARG VAULT_VERSION
ARG DOCKER_CACHE_KEY
ARG DOCKER_CACHE_PURGE
ARG GITHUB_REPOSITORY_OWNER=socheatsok78-lab
RUN --mount=type=cache,sharing=locked,id=${DOCKER_CACHE_KEY}/${VAULT_VERSION}/go/pkg/mod,target=/go/pkg/mod \
    --mount=type=tmpfs,target=/root/.cache/go-build \
<<EOF
    apk add --no-cache --virtual .build-deps curl bash git patch

    go mod tidy
    # (cd api && go mod tidy)
    # (cd sdk && go mod tidy)

    GIT_IMPORT="github.com/openbao/openbao/version"
    GIT_COMMIT=$(git rev-parse --short HEAD)
    GIT_COMMIT_YEAR=$(git show -s --format=%cd --date=format:%Y HEAD)
    GIT_DIRTY=$(test -n "`git status --porcelain`" && echo "+CHANGES" || true)
    GIT_DIRTY=${GIT_DIRTY}${GITHUB_REPOSITORY_OWNER:+"+${GITHUB_REPOSITORY_OWNER}"}
    DATE_FORMAT="%Y-%m-%dT%H:%M:%SZ"
    GIT_DATE=$(date -u +${DATE_FORMAT})

    GOTAGS="vault ui"
    GOLDFLAGS="-w -s"
    GOLDFLAGS="${GOLDFLAGS} -X ${GIT_IMPORT}.fullVersion=${VAULT_VERSION}"
    GOLDFLAGS="${GOLDFLAGS} -X ${GIT_IMPORT}.GitCommit=${GIT_COMMIT}${GIT_DIRTY}"
    GOLDFLAGS="${GOLDFLAGS} -X ${GIT_IMPORT}.BuildDate=${GIT_DATE}"
    for GOARCH in amd64 arm64; do
        mkdir -p ./pkg/bin/linux_${GOARCH}
        (set -x; CGO_ENABLED=0 GOOS=linux GOARCH=${GOARCH} go build -o ./pkg/bin/linux_${GOARCH} -tags "${GOTAGS}" -ldflags "${GOLDFLAGS}" .)
    done

    # cleanup, if requested
    if [[ "${DOCKER_CACHE_PURGE}" == "true" ]]; then
        rm -rf /go/pkg/mod/*
        rm -rf /root/.cache/go-build/*
    fi
    apk del .build-deps
EOF

# Final stage
FROM openbao
ARG TARGETARCH
COPY --link --from=stage2 /vault/pkg/bin/linux_${TARGETARCH}/openbao /bin/bao
RUN ln -s /bin/bao /bin/vault
USER openbao
