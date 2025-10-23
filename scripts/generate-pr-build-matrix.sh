#!/usr/bin/env bash
set -euo pipefail

# This script detects files changed in a pull request compared to the main branch.
# It looks for Dockerfiles among the changed files and generates a build matrix accordingly.
# Example:
# consul/1.22.0/Dockerfile
# vault/1.10.0/Dockerfile

GITHUB_BASE_REF=${GITHUB_BASE_REF:-main}
GITHUB_HEAD_REF=${GITHUB_HEAD_REF:-}
GITHUB_OUTPUT=${GITHUB_OUTPUT:-/dev/stdout}

if [ -z "$GITHUB_HEAD_REF" ]; then
  echo "This script should be run in the context of a pull request."
  exit 1
fi

declare -a build_matrix=()
for file in $(git diff "origin/${GITHUB_BASE_REF}" "HEAD" --name-only); do
	if [[ "${file}" == *"Dockerfile" ]]; then
		# Extract target and version from the file path
		target=$(echo "${file}" | cut -d'/' -f1)
		version=$(echo "${file}" | cut -d'/' -f2)
		build_matrix+=("{\"target\":\"${target}\",\"version\":\"${version}\"}")
		echo "Added to build matrix: target=${target}, version=${version}"
	fi
done

# Build JSON array and write to GITHUB_OUTPUT, quoting to prevent word splitting.
matrix_json=$(printf '%s\n' "${build_matrix[@]}" | jq -sc '.')
echo "matrix=${matrix_json}" >> "$GITHUB_OUTPUT"
