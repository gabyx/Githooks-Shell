#!/usr/bin/env bash
# shellcheck disable=SC1090,SC1091

set -e
set -u

ROOT_DIR=$(git rev-parse --show-toplevel)
. "$ROOT_DIR/tests/general.sh"

hookNs=$(getHookNamespace)

function clean_up() {
    docker rmi "$hookNs-testing:base" &>/dev/null || true
    docker rmi "$hookNs-testing:finale" &>/dev/null || true
}

trap clean_up EXIT

docker build --force-rm \
    --build-arg "ROOT_ACCESS=true" \
    -t "$hookNs-testing:base" \
    -f "$ROOT_DIR/githooks/container/Dockerfile" \
    --target "$hookNs-user" "$ROOT_DIR" ||
    die "Could not build container."

export ADDITIONAL_PRE_INSTALL_STEPS=''
"$ROOT_DIR/tests/exec-tests.sh" "$@"

# Test without parallel
export ADDITIONAL_PRE_INSTALL_STEPS="
$ADDITIONAL_PRE_INSTALL_STEPS
RUN sudo apk del parallel
"

"$ROOT_DIR/tests/exec-tests.sh" "$@"
