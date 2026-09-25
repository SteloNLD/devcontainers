#!/usr/bin/env bash
set -e

# The version option defaults to "latest" and is resolved here rather than frozen
# in this file -- the same approach the upstream devcontainer features take.
# Reproducibility comes from pinning the built image, not from a number in here.
# An explicit version is passed straight through.
resolve_version() {
  [ "$1" != "latest" ] && { echo "$1"; return; }
  if command -v git >/dev/null 2>&1; then
    # --refs drops the ^{} peel entries git otherwise emits for annotated tags.
    git ls-remote --tags --refs "$2" 2>/dev/null | sed 's#.*/tags/##; s#^v##'
  else
    # No git on this base. The API works but is rate-limited per IP, so git wins
    # when it is there.
    curl -fsSL "https://api.github.com/repos/${2#https://github.com/}/tags?per_page=100" 2>/dev/null \
      | grep -o '"name": *"[^"]*"' | sed 's/.*"name": *"//; s/"$//; s/^v//'
  fi | grep -E '^[0-9]+\.[0-9]+(\.[0-9]+)?$' | sort -rV | head -1
  # The grep keeps stable tags only, so alphas, betas, RCs and previews -- which
  # opentofu, packer and PowerShell all publish -- can never win the sort.
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
