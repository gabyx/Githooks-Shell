#!/usr/bin/env bash
# shellcheck disable=SC1090,SC1091,SC2015
# Test:
#   Run shellcheck hook on staged files

set -u

. "$GH_TEST_REPO/tests/general.sh"

function finish() {
    cleanRepos
}
trap finish EXIT

initGit || die "Init failed"
installHook "$GH_TEST_REPO/githooks/pre-commit" -and -path '*/2-check/.check-shell-mistakes.sh' ||
    die "Install hook failed"

shellcheck --version || die "shellcheck not available."

function setupFiles() {
    # Stupid format because of Githooks hooks.
    echo -ne "#!/usr/bin/env bash\n#shellcheck" >"A1.sh"
    echo -e " disable=SC2016\necho  '\$a'" >>"A1.sh"

    echo -ne "#!/usr/bin/env bash\necho 'a' && set" >"A2.sh"
    echo " -uax" >>"A2.sh"

    echo -e " # shellcheck disable=all\necho  '\$a'" >>"A3.sh"
    echo -e " # shellcheck disable=1000\necho  '\$a'" >>"A5.sh"
    echo -e " # shellcheck disable=SC1000, SC1230,SC12411243\necho  '\$a'" >>"A6.sh"
}

setupFiles ||
    die "Could not make test sources."

git add . || die "Could not add files."

s="set"
out=$(git commit -a -m "Checking files." 2>&1)
# shellcheck disable=SC2181
if [ $? -eq 0 ] ||
    ! echo "$out" | grep -qi "wrong shellcheck ignore.*A1.sh" ||
    ! echo "$out" | grep -qi "detected '$s -x'.*A2.sh" ||
    echo "$out" | grep -qi "A3.sh" ||
    ! echo "$out" | grep -qi "wrong shellcheck ignore.*A5.sh" ||
    echo "$out" | grep -qi "A6.sh"; then

    echo "Commit should not have happened."
    echo "$out"
    exit 1
fi
