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

VERSION=$(resolve_version "${VERSION}" "https://github.com/zoni/obsidian-export")
[ -n "$VERSION" ] || { echo "Could not resolve a version from https://github.com/zoni/obsidian-export" >&2; exit 1; }

ARCH=$(uname -m)

if [ "$ARCH" = "x86_64" ]; then
  curl -fsSL "https://github.com/zoni/obsidian-export/releases/download/v${VERSION}/obsidian-export-x86_64-unknown-linux-gnu.tar.xz" \
    | tar -xJ --strip-components=1 -C /usr/local/bin "obsidian-export-x86_64-unknown-linux-gnu/obsidian-export"
else
  # No prebuilt aarch64 Linux binary — compile from source then remove the toolchain
  curl --proto '=https' --tlsv1.2 -fsSf https://sh.rustup.rs | sh -s -- -y --profile minimal
  source "$HOME/.cargo/env"
  cargo install obsidian-export --version "${VERSION}"
  cp "$HOME/.cargo/bin/obsidian-export" /usr/local/bin/
  rustup self uninstall -y
fi

echo "Installed $(obsidian-export --version)"
