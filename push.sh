#!/usr/bin/env bash
# Push current branch to both origin (GitHub) and gitee.
set -euo pipefail

BRANCH="$(git rev-parse --abbrev-ref HEAD)"

git push origin "${BRANCH}"
git push gitee "${BRANCH}"
