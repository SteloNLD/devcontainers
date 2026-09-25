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

VERSION=$(resolve_version "${VERSION}" "https://github.com/direnv/direnv")
[ -n "$VERSION" ] || { echo "Could not resolve a version from https://github.com/direnv/direnv" >&2; exit 1; }

ARCH=$(uname -m)
case "$ARCH" in
  x86_64)  DIRENV_ARCH="amd64" ;;
  aarch64) DIRENV_ARCH="arm64" ;;
  *)       echo "Unsupported architecture: $ARCH"; exit 1 ;;
esac

curl -fsSL "https://github.com/direnv/direnv/releases/download/v${VERSION}/direnv.linux-${DIRENV_ARCH}" \
  -o /usr/local/bin/direnv
chmod +x /usr/local/bin/direnv

# Where the hook goes depends on the distro, and getting it wrong fails silently —
# the shell simply never hooks direnv.
#   Debian/Ubuntu: interactive non-login bash reads /etc/bash.bashrc, and that file
#                  does NOT source /etc/profile.d.
#   Fedora/RHEL:   there is no /etc/bash.bashrc; /etc/bashrc sources
#                  /etc/profile.d/*.sh for interactive non-login shells too.
HOOK='eval "$(direnv hook bash)"'
if [ -f /etc/bash.bashrc ]; then
  echo "$HOOK" >> /etc/bash.bashrc
  HOOK_TARGET=/etc/bash.bashrc
elif [ -d /etc/profile.d ]; then
  echo "$HOOK" > /etc/profile.d/direnv.sh
  chmod +x /etc/profile.d/direnv.sh
  HOOK_TARGET=/etc/profile.d/direnv.sh
else
  echo "Could not find a shell startup file to hook direnv into" >&2
  exit 1
fi

echo "Installed $(direnv --version), hooked via ${HOOK_TARGET}"
