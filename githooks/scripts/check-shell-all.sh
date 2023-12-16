#!/usr/bin/env bash
# shellcheck disable=SC1090,SC1091

set -u
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
. "$DIR/../common/log.sh"
. "$DIR/../common/parallel.sh"
. "$DIR/../common/shell-check.sh"

dryRun="true"
dir=""
excludeRegex=""
regex=${3:-$(getGeneralShellFileRegex)}

function help() {
    printError "Usage:" \
        "  [--force]                      : Force the format." \
        "  [--exclude-regex <regex> ]     : Exclude file with this regex." \
        "  [--glob-pattern <pattern>]     : Regex pattern to include files." \
        "   --dir <path>                  : In which directory to check files."
}

function parseArgs() {
    local prev=""

    for p in "$@"; do
        if [ "$p" = "--force" ]; then
            dryRun="false"
        elif [ "$p" = "--help" ]; then
            help
            return 1
        elif [ "$p" = "--dir" ]; then
            true
        elif [ "$prev" = "--dir" ]; then
            dir="$p"
        elif [ "$p" = "--exclude-regex" ]; then
            true
        elif [ "$prev" = "--exclude-regex" ]; then
            excludeRegex="$p"
        elif [ "$p" = "--regex-pattern" ]; then
            true
        elif [ "$prev" = "--regex-pattern" ]; then
            regex="$p"
        else
            printError "! Unknown argument \`$p\`"
            help
            return 1
        fi

        prev="$p"
    done
}

parseArgs "$@"

[ -d "$dir" ] || die "Directory '$dir' does not exist."

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
