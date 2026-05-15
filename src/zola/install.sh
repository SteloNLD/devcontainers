#!/usr/bin/env bash
set -e

ARCH=$(uname -m)
case "$ARCH" in
  x86_64)  ZOLA_ARCH="x86_64-unknown-linux-gnu" ;;
  aarch64) ZOLA_ARCH="aarch64-unknown-linux-gnu" ;;
  *)       echo "Unsupported architecture: $ARCH"; exit 1 ;;
esac

curl -fsSL "https://github.com/getzola/zola/releases/download/v${VERSION}/zola-v${VERSION}-${ZOLA_ARCH}.tar.gz" \
  | tar -xz -C /usr/local/bin zola

echo "Installed $(zola --version)"
