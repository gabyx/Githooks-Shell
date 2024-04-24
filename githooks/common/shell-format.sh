#!/usr/bin/env bash
# shellcheck disable=SC1090,SC1091,SC2015

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
. "$DIR/log.sh"
. "$DIR/version.sh"
. "$DIR/regex-sh.sh"

# Assert that 'shfmt' (`=$1`) has version `[$2, $3)`.
function assertShellFormatVersion() {
    local expectedVersionMin="$1"
    local expectedVersionMax="$2"
    local exe="${3:-shfmt}"

    command -v "$exe" &>/dev/null ||
        die "Tool '$exe' is not installed."

    local version
    version=$("$exe" --version | sed -E "s@v?([0-9]+\.[0-9]+\.[0-9]+).*@\1@")

    versionCompare "$version" ">=" "$expectedVersionMin" &&
        versionCompare "$version" "<" "$expectedVersionMax" ||
        die "Version of 'shfmt' is '$version' but should be '[$expectedVersionMin, $expectedVersionMax)'."

    printInfo "Version: shfmt '$version'."

    return 0
}

# Format a shell file inplace.
function formatShellFile() {
    local file="$1"
    local shellformatExe="${2:-shfmt}"

    printInfo " - ✍ Formatting file: '$file'"
    "$shellformatExe" -w -i 4 "$file" 1>&2 ||
        {
            printError "'$shellformatExe' failed for: '$file'"
            return 1
        }

    return 0
}
