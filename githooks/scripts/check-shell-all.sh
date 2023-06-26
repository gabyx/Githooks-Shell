#!/usr/bin/env bash
# shellcheck disable=SC1090,SC1091

set -u
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
. "$DIR/../common/log.sh"
. "$DIR/../common/parallel.sh"
. "$DIR/../common/shell-check.sh"

dir="${1:-}"
excludeRegex="${2:-}"
regex=${3:-$(getGeneralShellFileRegex)}

[ -d "$dir" ] || die "Directory '$dir' does not exist."

read -r -p "Shall we really format all files? (No, yes, dry run) [N|y|d]: " what

dryRun="false"

if [ "$what" = "d" ]; then
    what="y"
    dryRun="true"
fi

if [ "$what" = "y" ]; then

    if [ "$dryRun" = "false" ]; then
        assertShellCheckVersion "0.8.0" "0.10.0"
        printInfo "Formatting shell files in dir '$dir'."
    else
        printInfo "Dry-run formatting shell files in dir '$dir'."
    fi

    # Format with no config -> search directory tree upwards.
    parallelForDir checkShellFile \
        "$dir" \
        "$regex" \
        "$excludeRegex" \
        "$dryRun" \
        "shellcheck" ||
        die "Checking in '$dir' with '$regex'."

    parallelForDir checkShellMistakesFile \
        "$dir" \
        "$regex" \
        "$excludeRegex" \
        "$dryRun" ||
        die "Checking in '$dir' with '$regex'."
fi
