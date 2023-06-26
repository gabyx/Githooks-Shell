#!/usr/bin/env bash
# shellcheck disable=SC1090,SC1091


# Assert all staged files are set in env. variable `STAGED_FILES`.
function assertStagedFiles() {
    # Export if run without githooks...
    if [ -z "$STAGED_FILES" ]; then
        CHANGED_FILES=$(git diff --cached --diff-filter=ACMR --name-only)

        # shellcheck disable=SC2181
        if [ $? -eq 0 ]; then
            STAGED_FILES="$CHANGED_FILES"
        fi
    fi
}
