#!/usr/bin/env bash
# shellcheck disable=SC1091

set -e
set -u

. "$GH_TEST_REPO/tests/general.sh"

if [ "${1:-}" = "--skip-docker-check" ]; then
    shift
else
    if [ "$DOCKER_RUNNING" != "true" ]; then
        echo "! This script is only meant to be run in a Docker container"
        exit 1
    fi
fi

TEST_SHOW="false"
SEQUENCE=""
TEST_RUNS=0
FAILED=0
SKIPPED=0
FAILED_TEST_LIST=""

if [ "${1:-}" = "--show-output" ]; then
    shift
    TEST_SHOW="true"
fi

if [ "${1:-}" = "--seq" ]; then
    shift
    SEQUENCE=$(for f in "$@"; do echo "step-$f"; done)
fi

# shellcheck disable=SC2317
function cleanUp() {
    set +e
    cleanDirs
}

trap cleanUp EXIT

function cleanDirs() {

    if [ -d "$GH_TEST_TMP" ]; then
        rm -rf "$GH_TEST_TMP" || {
            echo "! Cleanup failed."
            exit 1
        }
    fi
    mkdir -p "$GH_TEST_TMP"

    return 0
}

if [ -z "${GH_TESTS:-}" ] ||
    [ -z "${GH_TEST_REPO:-}" ] ||
    [ -z "${GH_TEST_TMP:-}" ]; then
    echo "! Missing env. variables." >&2
    exit 1
fi

echo "Test repo: '$GH_TEST_REPO'"
echo "Tests dir: '$GH_TESTS'"

startT=$(date +%s)

for STEP in "$GH_TESTS/steps"/step-*.sh; do
    STEP_NAME=$(basename "$STEP" | sed 's/.sh$//')
    STEP_DESC=$(grep -m 1 -A 1 "Test:" "$STEP" | tail -1 | sed 's/#\s*//')

    if [ -n "$SEQUENCE" ] && ! echo "$SEQUENCE" | grep -q "$STEP_NAME"; then
        continue
    fi

    echo "> Executing $STEP_NAME"
    echo "  :: $STEP_DESC"

    cleanDirs

    TEST_RUNS=$((TEST_RUNS + 1))

    {
        set +e
        TEST_OUTPUT=$("$STEP" 2>&1)
        TEST_RESULT=$?
        set -e
    }

    # shellcheck disable=SC2181
    if [ $TEST_RESULT -eq 249 ]; then
        REASON=$(echo "$TEST_OUTPUT" | tail -1)
        echo "  x  $STEP has been skipped, reason: $REASON"
        SKIPPED=$((SKIPPED + 1))
    elif [ $TEST_RESULT -eq 250 ]; then
        echo -e "  >  $STEP is benchmark:\n $TEST_OUTPUT"
        SKIPPED=$((SKIPPED + 1))
    elif [ $TEST_RESULT -ne 0 ]; then
        FAILURE=$(echo "$TEST_OUTPUT" | tail -1)
        echo "! $STEP has failed with code $TEST_RESULT ($FAILURE), output:" >&2
        echo "$TEST_OUTPUT" | sed -E "s/^/ x: /g" >&2
        FAILED=$((FAILED + 1))
        FAILED_TEST_LIST="$FAILED_TEST_LIST\n- $STEP ($TEST_RESULT -- $FAILURE)"

    elif [ "$TEST_SHOW" = "true" ]; then
        echo ":: Output was:"
        echo "$TEST_OUTPUT" | sed -E "s/^/  | /g"
    fi

    if [ $TEST_RESULT -eq 111 ]; then
        echo "! $STEP triggered fatal test abort." >&2
        break
    fi

    cleanDirs

    echo

done

endT=$(date +%s)
elapsed=$((endT - startT))

echo "$TEST_RUNS tests run: $FAILED failed and $SKIPPED skipped"
echo "Run time: $elapsed seconds"
echo

if [ -n "$FAILED_TEST_LIST" ]; then
    echo -e "Failed tests: $FAILED_TEST_LIST" >&2
    echo
fi

if [ $FAILED -ne 0 ]; then
    exit 1
else
    exit 0
fi
