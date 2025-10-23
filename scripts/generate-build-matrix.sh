#!/usr/bin/env bash
set -euo pipefail

# This script detects files changed in a pull request compared to the main branch.
# It looks for Dockerfiles among the changed files and generates a build matrix accordingly.
# Example:
# consul/1.22.0/Dockerfile
# vault/1.10.0/Dockerfile

declare -a build_matrix=()
for file in $(git diff-tree --no-commit-id --name-only HEAD -r); do
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
