#!/usr/bin/env bash
# shellcheck disable=SC1090,SC1091


function stageFiles() {
    local files="$1"
    [ -n "$files" ] || return 0

    echo "$files" | git add --pathspec-from-file=- || return 1
    return 0
}
