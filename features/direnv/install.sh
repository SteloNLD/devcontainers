#!/usr/bin/env bash
set -e

ARCH=$(uname -m)
case "$ARCH" in
  x86_64)  DIRENV_ARCH="amd64" ;;
  aarch64) DIRENV_ARCH="arm64" ;;
  *)       echo "Unsupported architecture: $ARCH"; exit 1 ;;
esac

curl -fsSL "https://github.com/direnv/direnv/releases/download/v${VERSION}/direnv.linux-${DIRENV_ARCH}" \
  -o /usr/local/bin/direnv
chmod +x /usr/local/bin/direnv

echo 'eval "$(direnv hook bash)"' >> /etc/bash.bashrc

echo "Installed $(direnv --version)"
