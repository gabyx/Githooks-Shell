#!/usr/bin/env bash
# shellcheck disable=SC1090,SC1091

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
ROOT_DIR="$DIR/../../.."
. "$ROOT_DIR/githooks/common/export-staged.sh"
. "$ROOT_DIR/githooks/common/parallel.sh"
. "$ROOT_DIR/githooks/common/shell-format.sh"
. "$ROOT_DIR/githooks/common/stage-files.sh"
. "$ROOT_DIR/githooks/common/log.sh"

assertStagedFiles || die "Could not assert staged files."

printHeader "Running hook: Shell format ..."

assertShellFormatVersion "3.4.0" "9.9.99"

regex=$(getGeneralShellFileRegex) || die "Could not get shell file regex."
parallelForFiles formatShellFile \
    "$STAGED_FILES" \
    "$regex" \
    "false" \
    "shfmt" || die "Shell format failed."

stageFiles "$PARALLEL_EXECUTED_FILES" ||
    printError "Could not stage formatted files."
