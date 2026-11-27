# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

Container images for Consul, Vault and OpenBao built **from upstream source**, with `github.com/hashicorp/go-discover` swapped for the fork `github.com/socheatsok78-lab/go-discover` (branch/tag `go-netaddrs-*`), which adds `hashicorp/go-netaddrs` as a discovery provider. Images publish to `ghcr.io/socheatsok78-lab/<target>:<version>` for `linux/amd64` and `linux/arm64`. There is no application code here, only Dockerfiles, bake files and CI.

## Layout and build model

Each target directory (`consul/`, `vault/`, `openbao/`) has the same shape:

- `base/Dockerfile`: the runtime image (alpine, user, dirs, volumes, ports, entrypoint). Never published on its own (tag `:base-cacheonly`).
- `<version>/Dockerfile`: one per upstream release. Multi-stage: clone upstream at `v${VERSION}` → build the UI with Node → `go mod edit -replace` go-discover with the fork, `go mod tidy`, cross-compile with `CGO_ENABLED=0 GOARCH=$TARGETARCH` on `$BUILDPLATFORM` → `FROM <target>` copies the binary into the base.
- `docker-bake.hcl`: `<target>_base` builds `base/`, and the `<target>` target uses `context = "${VERSION}"` and injects the base through `contexts = { "<target>" = "target:<target>_base" }`. That is why the final stage of each versioned Dockerfile is `FROM consul` / `FROM vault` / `FROM openbao`. `VERSION` is required, and bake validation fails if it is empty.

Per-target quirks:
- OpenBao Dockerfiles reuse `ARG VAULT_VERSION` for the OpenBao version, pin a specific `GO_VERSION` (e.g. `1.25.8`), inject `version.fullVersion` through ldflags, install the binary as `/bin/bao` with a `/bin/vault` symlink, and run as `USER openbao`.
- Vault's `base/Dockerfile` pulls `docker-entrypoint.sh` from upstream `main` at build time, so it is not pinned.
- Vault runs `go mod tidy` in `api/` and `sdk/` too. Consul and OpenBao have those lines commented out.

## Adding a new upstream version (the most common change)

Version Dockerfiles within a target are identical except for the first `ARG <X>_VERSION=` line. Copy the latest one and bump that line:

```sh
cp -r vault/2.1.0 vault/2.1.1 && sed -i '' '1s/2.1.0/2.1.1/' vault/2.1.1/Dockerfile
```

Bump `GO_VERSION`, `NODE_VERSION` or `GO_DISCOVER_VERSION` only when upstream requires it. Branches and PRs follow the pattern `<target>/<version>` (e.g. `vault/2.1.0`), one version per PR.

## Local commands

Run from the repo root (dispatches into the target dir) or from inside a target dir:

```sh
make vault            # print TARGET / VERSION (VERSION auto-detected as newest <version>/ dir)
make vault print      # docker buildx bake vault --print
make vault build      # bake for the local platform only (--set *.platform=)
```

To build a specific version, override `VERSION`: `VERSION=2.0.4 make -C vault build`, or `cd vault && VERSION=2.0.4 docker buildx bake vault --set '*.platform='`. Full source builds (UI and Go) are slow. Use `print` to check bake changes.

CI matrix scripts can be dry-run locally (they need `jq`; `GITHUB_OUTPUT` defaults to `/dev/null`):

```sh
./.github/scripts/generate-build-matrix.sh vault            # all versions of a target
GITHUB_HEAD_REF=x ./.github/scripts/generate-pr-build-matrix.sh   # diff vs origin/main
```

## CI (`.github/workflows/`)

- `pr-build.yml`: `generate-pr-build-matrix.sh` diffs against `origin/main`. A changed `<target>/<version>/Dockerfile` builds that version. A change to `<target>/base/` or `<target>/docker-bake.hcl` rebuilds **every** version of that target. Builds do not push by default. With the **`pr-pull` label**, CI logs in, pushes to GHCR, writes the GHA cache, and then **auto-merges the PR** (`gh pr merge --merge --delete-branch`).
- `build.yml`: manual `workflow_dispatch` with optional `target`/`version`/`push`. If target and version are both blank, it rebuilds every version of every target.
- `use-docker-buildx-bake.yml`: reusable workflow. Runs `docker/bake-action` with `source: {{defaultContext}}:<target>` (the target dir is the bake cwd), merges metadata-action and github-metadata-action bake files (the `docker-metadata-action` / `github-metadata-action` targets that `<target>` inherits), and sets `BUILDKIT_CONTEXT_KEEP_GIT_DIR=1`.
