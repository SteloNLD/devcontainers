#!/usr/bin/env bash
set -e

pipx install ansible-navigator

cat <<'EOF' >> /etc/bash.bashrc

# Wrap ansible-navigator so Execution Environments run transparently under
# Docker-outside-of-Docker, where the EE is a sibling container the host's daemon
# starts. Two things that daemon can't resolve on its own, handled here so nothing
# leaks onto the command line:
#   TMPDIR        -> runner's private_data_dir must sit inside the workspace bind
#                    mount (a path both the devcontainer and the daemon see); the
#                    default /tmp isn't shared, which breaks the awx_display callback.
#   SSH_AUTH_SOCK -> drop it so navigator doesn't auto-forward the devcontainer's
#                    agent socket (unreachable by the sibling); ansible-navigator.yml
#                    mounts the runtime's own agent socket instead.
ansible-navigator() {
  local tmpdir="${PWD}/.ansible-navigator-tmp"
  mkdir -p "$tmpdir"
  ( unset SSH_AUTH_SOCK; TMPDIR="$tmpdir" command ansible-navigator "$@" )
}
EOF

echo "Installed $(ansible-navigator --version)"
