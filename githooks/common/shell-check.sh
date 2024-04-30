#!/usr/bin/env bash
# shellcheck disable=SC1090,SC1091,SC2015

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
. "$DIR/log.sh"
. "$DIR/version.sh"
. "$DIR/regex-sh.sh"

# Assert that 'shellcheck' (`=$1`) has version `[$2, $3)`.
function assertShellCheckVersion() {
    local expectedVersionMin="$1"
    local expectedVersionMax="$2"
    local exe="${3:-shellcheck}"

    command -v "$exe" &>/dev/null ||
        die "Tool '$exe' is not installed."

    local version
    version=$("$exe" --version | grep -m 1 "version" | sed -E "s@.* ([0-9]+\.[0-9]+\.[0-9]+).*@\1@")

    versionCompare "$version" ">=" "$expectedVersionMin" &&
        versionCompare "$version" "<" "$expectedVersionMax" ||
        die "Version of 'shellcheck' is '$version' but should be '[$expectedVersionMin, $expectedVersionMax)'."

    printInfo "Version: shellcheck '$version'."

    return 0
}

# Check a shell file inplace.
function checkShellFile() {
    local file="$1"
    local shellcheckExe="${2:-shellcheck}"

    printInfo " ✔️ Checking file: '$file'"
    "$shellcheckExe" -e SC1071 "$file" 1>&2 ||
        {
            printError "'$shellcheckExe' failed for: '$file'"
            return 1
        }

    return 0
}

# Check a shell file's ignore format.
function checkShellMistakesFile() {
    local file="$1"

    if grep -nrHE 'shellcheck.*disable' "$file" | grep -qEv '# shellcheck disable=(SC[0-9]+((,\s*SC[0-9]+)*)|all)$'; then
        printError "Wrong shellcheck ignore format: use '# shellcheck disable=SCnnnn[,SCnnnn]|all' in '$file'"
        return 1
    fi

    if grep -qnrHE "set\s+[-+][a-z]*x" "$file"; then
        # Ugly writing to pass 'seT -x' check.
        msg="Detected 'set"
        msg="$msg -x' in '$file'. This is wrong."
        printError "$msg"
        return 1
    fi

    return 0
}
