#!/usr/bin/env bash
set -e

# --include-deps exposes the apps of ansible-navigator's own dependencies —
# ansible, ansible-playbook, ansible-galaxy, ansible-lint and friends. They are
# already in this venv (navigator depends on ansible-lint, which depends on
# ansible-core), so this costs nothing and removes any need for a separate
# ansible install alongside it.
pipx install --include-deps ansible-navigator

echo "Installed $(ansible-navigator --version)"
echo "Exposed   $(ansible --version | head -1)"
echo "Exposed   $(ansible-lint --version | head -1)"
