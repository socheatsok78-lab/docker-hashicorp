#!/usr/bin/env bash
set -euo pipefail

# This script detects files changed in a pull request compared to the main branch.
# It looks for Dockerfiles among the changed files and generates a build matrix accordingly.
# Example:
# consul/1.22.0/Dockerfile
# vault/1.10.0/Dockerfile

GITHUB_BASE_REF=${GITHUB_BASE_REF:-main}
GITHUB_HEAD_REF=${GITHUB_HEAD_REF:-}
GITHUB_OUTPUT=${GITHUB_OUTPUT:-/dev/null}

RUNNER_TEMP=${RUNNER_TEMP:-$(pwd)}
BUILD_MATRIX_MANIFEST=$(mktemp -p "${RUNNER_TEMP}")

if [ -z "$GITHUB_HEAD_REF" ]; then
  echo "This script should be run in the context of a pull request."
  exit 1
fi

BASE_IMAGE_CHANGES=""

echo "File changed:"
for file in $(git diff "origin/${GITHUB_BASE_REF}" "HEAD" --name-only); do
	echo "- ${file}"
	if [[ "${file}" == *"/.empty" ]] || [[ "${file}" == *"/Dockerfile" ]]; then
		# Extract target and version from the file path
		target=$(echo "${file}" | cut -d'/' -f1)
		version=$(echo "${file}" | cut -d'/' -f2)
		if [[ "${version}" == "base" ]]; then
			echo "- Skipping ${version} change for ${target} as it is a base image and not a specific version."
			BASE_IMAGE_CHANGES+=" ${target}"
			continue
		fi
		# Add to build matrix
		echo "{\"target\":\"${target}\",\"version\":\"${version}\"}" >> "$BUILD_MATRIX_MANIFEST"
	fi
done

# If any template Dockerfile has changed, we need to run the full build matrix generation script to ensure all relevant targets are included.
if [ -n "$BASE_IMAGE_CHANGES" ]; then
	echo "::warning::The template files have changed. Running the full build matrix generation script to ensure all relevant targets are included."
	"$(dirname "$0")"/generate-build-matrix.sh "${BASE_IMAGE_CHANGES}"
	exit 0
fi

# Build JSON array and write to GITHUB_OUTPUT, quoting to prevent word splitting.
echo "Generating build matrix..."
cat "$BUILD_MATRIX_MANIFEST" | sort | uniq | jq -s '.'

# Set the output variable for GitHub Actions
matrix_json=$(cat "$BUILD_MATRIX_MANIFEST" | sort | uniq | jq -sc '.')
echo "matrix=${matrix_json}" >> "$GITHUB_OUTPUT"

# Clean up
rm -f "$BUILD_MATRIX_MANIFEST" || true
