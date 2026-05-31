#!/usr/bin/env bash
set -e

export PIPX_HOME=${PIPX_HOME:-"/usr/local/py-utils"}
export PIPX_BIN_DIR="${PIPX_HOME}/bin"
export PATH="${PATH}:${PIPX_BIN_DIR}"

pipx inject ansible-core ansible-lint

echo "Installed $(ansible-lint --version)"
