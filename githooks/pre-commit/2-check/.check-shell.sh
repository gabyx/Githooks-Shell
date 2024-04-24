#!/usr/bin/env bash
# shellcheck disable=SC1090,SC1091

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
ROOT_DIR="$DIR/../../.."
. "$ROOT_DIR/githooks/common/export-staged.sh"
. "$ROOT_DIR/githooks/common/parallel.sh"
. "$ROOT_DIR/githooks/common/shell-check.sh"
. "$ROOT_DIR/githooks/common/stage-files.sh"
. "$ROOT_DIR/githooks/common/log.sh"

assertStagedFiles || die "Could not assert staged files."

printHeader "Running hook: Shell check ..."

assertShellCheckVersion "0.8.0" "0.10.0"

regex=$(getGeneralShellFileRegex) || die "Could not get shell file regex."
parallelForFiles checkShellFile \
    "$STAGED_FILES" \
    "$regex" \
    "false" || die "Shell check failed."
