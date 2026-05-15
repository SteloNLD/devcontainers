#!/usr/bin/env bash
set -e

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
