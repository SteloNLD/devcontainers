#!/usr/bin/env bash
set -e

ARCH=$(uname -m)
case "$ARCH" in
  x86_64)  PKR_ARCH="amd64" ;;
  aarch64) PKR_ARCH="arm64" ;;
  *)       echo "Unsupported architecture: $ARCH"; exit 1 ;;
esac

curl -fsSL "https://releases.hashicorp.com/packer/${VERSION}/packer_${VERSION}_linux_${PKR_ARCH}.zip" \
  -o /tmp/packer.zip
unzip -q /tmp/packer.zip -d /usr/local/bin packer
rm /tmp/packer.zip

echo "Installed $(packer --version)"
