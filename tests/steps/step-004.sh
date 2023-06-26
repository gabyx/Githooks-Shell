#!/usr/bin/env bash
# shellcheck disable=SC1090,SC1091,SC2015
# Test:
#   Run version checks

set -e
set -u

. "$GH_TEST_REPO/tests/general.sh"
. "$GH_TEST_REPO/githooks/common/version.sh"

function P { echo -n "$@"; }
function expect {
    echo "$1" | grep -qE "[+_]" || {
        echo "Wrong expect!" >&2
        return 1
    }
    echo "$1"
}
P 'Note: ++ (true) and __ (false) mean that versionCompare works correctly.\n'

function test_all() {
    versionCompare 2.5 '!=' 2.5 && P + || P _
    expect _

    versionCompare 2.5 '=' 2.5 && P + || P _
    expect +

    versionCompare 2.5 '==' 2.5 && P + || P _
    expect +

    versionCompare 2.5a '==' 2.5b && P + || P _
    expect _

    versionCompare 2.5a '<' 2.5b && P + || P _
    expect +

    versionCompare 2.5a '>' 2.5b && P + || P _
    expect _

    versionCompare 2.5b '>' 2.5a && P + || P _
    expect +

    versionCompare 2.5b '<' 2.5a && P + || P _
    expect _

    versionCompare 3.5 '<' 3.5b && P + || P _
    expect +

    versionCompare 3.5 '>' 3.5b && P + || P _
    expect _

    versionCompare 3.5b '>' 3.5 && P + || P _
    expect +

    versionCompare 3.5b '<' 3.5 && P + || P _
    expect _

    versionCompare 3.6 '<' 3.5b && P + || P _
    expect _

    versionCompare 3.6 '>' 3.5b && P + || P _
    expect +

    versionCompare 3.5b '<' 3.6 && P + || P _
    expect +

    versionCompare 3.5b '>' 3.6 && P + || P _
    expect _

    versionCompare 2.5.7 '<=' 2.5.6 && P + || P _
    expect _

    versionCompare 2.4.10 '<' 2.4.9 && P + || P _
    expect _

    versionCompare 2.4.10 '<' 2.5.9 && P + || P _
    expect +

    versionCompare 3.4.10 '<' 2.5.9 && P + || P _
    expect _

    versionCompare 2.4.8 '>' 2.4.10 && P + || P _
    expect _

    versionCompare 2.5.6 '<=' 2.5.6 && P + || P _
    expect +

    versionCompare 2.5.6 '>=' 2.5.6 && P + || P _
    expect +

    versionCompare 3.0 '<' 3.0.3 && P + || P _
    expect +

    versionCompare 3.0002 '<' 3.0003.3 && P + || P _
    expect +

    versionCompare 3.0002 '>' 3.0003.3 && P + || P _
    expect _

    versionCompare 3.0003.3 '<' 3.0002 && P + || P _
    expect _

    versionCompare 3.0003.3 '>' 3.0002 && P + || P _
    expect +

    versionCompare 4.0-RC2 '>' 4.0-RC1 && P + || P _
    expect +

    versionCompare 4.0-RC2 '<' 4.0-RC1 && P + || P _
    expect _

    versionCompare 0.0.9 '<' 0.10.0 && P + || P _
    expect +

    versionCompare 0.0.9 '>' 0.10.0 && P + || P _
    expect _
}

out=$(test_all) || exit 1
echo "$out"
if echo "$out" | grep -qE "_\+|\+_"; then
    echo "Some version tests failed."
    exit 1
fi
