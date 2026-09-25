#!/usr/bin/env bash
set -e

# The version option defaults to "latest" and is resolved here rather than frozen
# in this file -- the same approach the upstream devcontainer features take.
# Reproducibility comes from pinning the built image, not from a number in here.
# An explicit version is passed straight through.
resolve_version() {
  # An explicit version returns before any network access, so a base without git
  # can still use this feature by pinning instead of asking for "latest".
  [ "$1" != "latest" ] && { echo "$1"; return; }
  command -v git >/dev/null 2>&1 || {
    echo "Resolving \"latest\" needs git; install git or pass an explicit version." >&2
    return 1
  }
  # git ls-remote rather than the GitHub API: the API is 60 requests/hour per IP
  # unauthenticated, and CI runners share address pools. --refs drops the ^{} peel
  # entries git emits for annotated tags; the grep keeps stable tags only, so the
  # alphas, betas, RCs and previews that opentofu, packer and PowerShell publish
  # can never win the sort.
  git ls-remote --tags --refs "$2" 2>/dev/null \
    | sed 's#.*/tags/##; s#^v##' \
    | grep -E '^[0-9]+\.[0-9]+(\.[0-9]+)?$' \
    | sort -rV | head -1
}

VERSION=$(resolve_version "${VERSION}" "https://github.com/hashicorp/packer")
[ -n "$VERSION" ] || { echo "Could not resolve a version from https://github.com/hashicorp/packer" >&2; exit 1; }

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
