#!/usr/bin/env bash
set -e

pipx install ansible-navigator

echo "Installed $(ansible-navigator --version)"
