#!/usr/bin/env bash
set -e

pipx inject ansible-core ansible-navigator

echo "Installed $(ansible-navigator --version)"
