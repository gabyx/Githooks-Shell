#!/usr/bin/env bash
# shellcheck disable=SC1091

ROOT_DIR=${ROOT_DIR:-$GH_TEST_REPO}
. "$ROOT_DIR/githooks/common/log.sh"

function getHookNamespace() {
    cat githooks/.namespace
}

function makeRandomCommit() {
    echo "Make commit: '$1'"
    echo "$1" >A.txt
    git add "A.txt" &>/dev/null
    echo -e "$1" | git commit --allow-empty --allow-empty-message -a -F - || return 1
}

function makeCommit() {
    makeRandomCommit "[np] Test $1\n\nReviewer: gabnue" || return 1
}

function initGit() {
    cleanRepos

    initCommit="${1:-}"

    # When githooks is installed, the inits will contain the hooks!
    repoDirServer=$(mktemp -d)
    (cd "${repoDirServer}" && git init --bare) || return 1

    repoDir=$(mktemp -d)
    (git clone "${repoDirServer}" "$repoDir") || return 1
    cd "$repoDir" || return 1

    git checkout -b master || return 1
    touch initFile
    git add initFile || return 1

    if [ "$initCommit" = "--initCommit" ]; then
        git commit -a -m "Task #11111 - Initial commit" || return 1
    fi

    echo "Repo: '$repoDir'"
    echo "Repo Server: '$repoDirServer'"

    return 0
}

function cleanRepos() {
    [ -d "${repoDir:-}" ] && rm -rf "$repoDir" &>/dev/null
    [ -d "${repoDir:-}" ] && rm -rf "$repoDirServer" &>/dev/null
    return 0
}

function installHook() {
    local hookPath="$1"
    local hookName
    hookName=$(basename "$1")
    shift

    # shellcheck disable=SC2124
    args="$@"

    for repo in "$repoDir" "$repoDirServer"; do

        # shellcheck disable=SC2086,SC2155
        local hooks=$(find "$hookPath" \
            -type f $args | sed -e 's/\(.*\)/bash \1 "$@" || exit 1 /')

        if [ -d "$repo/.git" ]; then
            folder="$repo/.git/hooks"
        elif [ -d "$repo" ]; then
            folder="$repo/hooks"
        else
            return 1
        fi

        mkdir -p "$folder" || true
        local hook="$folder/$hookName"
        echo "Installing hook '$hook' ..."
        echo "#!/usr/bin/env bash" >"$hook"
        echo "echo 'Testing Hooks: $hookName -> $hooks'" >>"$hook"
        echo "$hooks" >>"$hook"
        chmod u+x "$hook"

    done

    return 0
}
