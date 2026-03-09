#!/usr/bin/env bash
set -euo pipefail

# This script detects files changed in a pull request compared to the main branch.
# It looks for Dockerfiles among the changed files and generates a build matrix accordingly.
# Example:
# library/{version}/Dockerfile
GITHUB_OUTPUT=${GITHUB_OUTPUT:-/dev/null}

RUNNER_TEMP=${RUNNER_TEMP:-$(pwd)}
BUILD_MATRIX_MANIFEST=$(mktemp -p "${RUNNER_TEMP}")
trap 'rm -f "$BUILD_MATRIX_MANIFEST"' EXIT

IMAGES=${IMAGES:-${@}}
if [[ -z "${IMAGES}" ]]; then
	# shellcheck disable=SC2231
	IMAGES=$(ls **/docker-bake.hcl | cut -d/ -f1)
fi

echo "File changed:"
# shellcheck disable=SC2231
for image in ${IMAGES}; do
	for file in ${image}/**/Dockerfile; do
		echo "- ${file}"
		if [[ "${file}" == *"/.empty" ]] || [[ "${file}" == *"/Dockerfile" ]]; then
			# Extract target and version from the file path
			target=$(echo "${file}" | cut -d'/' -f1)
			version=$(echo "${file}" | cut -d'/' -f2)
			if [[ "${version}" == "base" ]]; then
				echo "- Skipping ${version} change for ${target} as it is a base image and not a specific version."
				continue
			fi
			# Add to build matrix
			echo "{\"target\":\"${target}\",\"version\":\"${version}\"}" >> "$BUILD_MATRIX_MANIFEST"
		fi
	done
done

# Build JSON array and write to GITHUB_OUTPUT, quoting to prevent word splitting.
echo "Generating build matrix..."
cat "$BUILD_MATRIX_MANIFEST" | sort -r | uniq | jq -s '.'

# Set the output variable for GitHub Actions
matrix_json=$(cat "$BUILD_MATRIX_MANIFEST" | sort | uniq | jq -sc '.')
echo "matrix=${matrix_json}" >> "$GITHUB_OUTPUT"
