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
installHook "$GH_TEST_REPO/githooks/pre-commit" -and -path '*/2-check/.check-shell.sh' ||
    die "Install hook failed"

shellcheck --version || die "shellcheck not available."

function setupFiles() {
    echo -e "#!/usr/bin/env bash\necho '\$a'" >"A1.sh"
}

setupFiles ||
    die "Could not make test sources."

git add . || die "Could not add files."

out=$(git commit -a -m "Checking files." 2>&1)
# shellcheck disable=SC2181
if [ $? -eq 0 ] ||
    ! echo "$out" | grep -qi "checking.*A1.sh"; then
    echo "Commit should not have happened."
    echo "$out"
    exit 1
fi
