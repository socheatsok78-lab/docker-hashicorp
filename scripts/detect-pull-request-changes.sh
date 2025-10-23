#!/usr/bin/env bash

# This script detects files changed in a pull request compared to the main branch.
# It outputs the list of changed files to stdout.

GITHUB_BASE_REF=${GITHUB_BASE_REF:-main}
GITHUB_HEAD_REF=${GITHUB_HEAD_REF:-}

if [ -z "$GITHUB_HEAD_REF" ]; then
	echo "This script should be run in the context of a pull request."
	exit 1
fi

if git diff "${GITHUB_BASE_REF}" "${GITHUB_HEAD_REF}" --name-only; then
  exit 0
else
	echo "Failed to get the list of changed files."
	exit 1
fi
