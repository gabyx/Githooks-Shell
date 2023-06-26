#!/usr/bin/env bash
# shellcheck disable=SC1090,SC1091


# Get the number of processors or the default `$1` if it fails.
function getProcessorCountOrDefault() {

    procs=$(nproc 2>/dev/null)
    [ -z "$procs" ] && procs="$1"

    echo "$procs"
    return 0
}

# Execute command for files in directory `$1` with a file path regex `$2`.
# Defines a env. variable PARALLEL_EXECUTED_FILES
function parallelForFiles() {
    local command="$1"
    local files="$2"
    local filePathRegex="$3"
    local dryRun="${4:-true}"
    shift 4

    unset PARALLEL_EXECUTED_FILES

    # shellcheck disable=SC2163
    export -f die _print printInfo printError "$command"
    [ -t 1 ] && export FORCE_COLOR="1"

    files=$(echo "$files" | grep -E "$filePathRegex")

    if [ "$dryRun" = "true" ]; then
        if [ -n "$files" ]; then
            local list
            list="$(echo "$files" | sed -E "s/^/ - /g")"
            printInfo "Would execute command '$command' for the following files:\n$list"
        else
            printInfo "Would execute command '$command' for no files!"
        fi
        return 0
    fi

    # Check if no files...
    [ -n "$files" ] || return 0
    # shellcheck disable=SC2034
    PARALLEL_EXECUTED_FILES=$(printf "%s\n" "${files[@]}")

    local procs
    procs=$(getProcessorCountOrDefault 4)

    if command -v parallel &>/dev/null; then
        echo "$files" |
            SHELL=$(type -p bash) parallel -k -P "$procs" --quote "$command" "$@" {} || return 1
    else
        echo "$files" |
            xargs -P "$procs" -I {} bash -c "$command \"\$@\"" _ "$@" {} || return 1
    fi
}

# Execute command for all files in directory `$1` with a file path regex `$2`.
# Defines a env. variable PARALLEL_EXECUTED_FILES
function parallelForDir() {
    local command="$1"
    local dir="$2"
    local filePathRegex="$3"
    local excludePathRegex="${4:-}"
    local dryRun="${5:-true}"
    shift 5

    local -a excludes=()
    [ -n "$excludePathRegex" ] && excludes+=(-and -not -regex "$excludePathRegex")

    unset PARALLEL_EXECUTED_FILES

    # shellcheck disable=SC2163
    export -f die _print printInfo printError "$command"
    [ -t 1 ] && export FORCE_COLOR="1"

    local files
    files=$(find "$dir" -regextype posix-extended -type f -and -not -ipath "*/.git/*" -and -regex "$filePathRegex" "${excludes[@]}")

    if [ "$dryRun" = "true" ]; then
        if [ -n "$files" ]; then
            local list
            list="$(echo "$files" | sed -E "s/^/ - /g")"
            printInfo "Would execute command '$command' for the following files:\n$list"
        else
            printInfo "Would execute command '$command' for no files!"
        fi
        return 0
    fi

    # Check if no files...
    [ -n "$files" ] || return 0
    # shellcheck disable=SC2034
    PARALLEL_EXECUTED_FILES=$(printf "%s\n" "${files[@]}")

    local procs
    procs=$(getProcessorCountOrDefault 4)

    if command -v parallel &>/dev/null; then
        echo "$files" |
            SHELL=$(type -p bash) parallel -k -P "$procs" --quote "$command" "$@" {} || return 1
    else
        # shellcheck disable=SC2038,SC2016
        echo "$files" |
            xargs -P "$procs" -I {} bash -c "$command \"\$@\"" _ "$@" {} || return 1
    fi
    return 0
}
