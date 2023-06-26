#!/usr/bin/env bash
# shellcheck disable=SC1090,SC1091

set -u
set -e

ROOT_DIR=$(git rev-parse --show-toplevel)
. "$ROOT_DIR/tests/general.sh"

hookNs=$(getHookNamespace)

function clean_up() {
    docker rmi "$hookNs-testing:finale" &>/dev/null || true
}

trap clean_up EXIT

cat <<EOF | docker build \
    --force-rm \
    -t "$hookNs-testing:final" \
    -f - "$ROOT_DIR" || die "Could not build container."
FROM "$hookNs-testing:base" 

RUN mkdir -p /home/githooks/tmp
ENV GH_TEST_TMP=/home/githooks/tmp
ENV GH_TEST_REPO=/home/githooks/repo
ENV GH_TESTS="/home/githooks/repo/tests"
ENV DOCKER_RUNNING=true

${ADDITIONAL_PRE_INSTALL_STEPS:-}

# Add sources
ADD tests "\$GH_TESTS"
ADD githooks "\$GH_TEST_REPO/githooks"

RUN git config --global user.email "githook@test.com" && \\
    git config --global user.name "Githook Tests" && \\
    git config --global init.defaultBranch main && \\
    git config --global core.autocrlf false

RUN echo "Git version: \$(git --version)"
WORKDIR \$GH_TESTS
EOF

docker run --rm \
    "$hookNs-testing:final" \
    ./exec-steps.sh "$@"
