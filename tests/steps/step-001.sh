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
installHook "$GH_TEST_REPO/githooks/pre-commit" -and -path '*/1-format/.format-shell.sh' ||
    die "Install hook failed"

shfmt --version || die "shfmt not available."

function setupFiles() {
    echo -e "#!/usr/bin/env bash\n echo  'asd'" >"A1.sh"
}

setupFiles ||
    die "Could not make test sources."

git add . || die "Could not add files."

out=$(git commit -a -m "Formatting files." 2>&1)
# shellcheck disable=SC2181
if [ $? -ne 0 ] ||
    ! echo "$out" | grep -qi "formatting.*A1.sh"; then
    echo "Expected to have formatted all files."
    echo "$out"
    exit 1
fi

if ! git diff --name-only | grep -q "A1.sh"; then
    echo "Expected repository to dirty, formatted files are dirty."
    git status
    exit 1
fi

if git diff --name-only --cached | grep -q "A1.sh"; then
    echo "Formatted files are staged but should not."
    git status
    exit 1
fi

git commit -a --no-verify -m "Check in formatted files." || exit 1
setupFiles || die "Could not setup files again."

if [ "$(git status --short | grep -c 'A.*')" != "6" ]; then
    echo "Expected repository to be dirty, formatting did not work."
    git status
fi
