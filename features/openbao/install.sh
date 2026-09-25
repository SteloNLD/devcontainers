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

VERSION=$(resolve_version "${VERSION}" "https://github.com/openbao/openbao")
[ -n "$VERSION" ] || { echo "Could not resolve a version from https://github.com/openbao/openbao" >&2; exit 1; }

ARCH=$(uname -m)
case "$ARCH" in
  x86_64)  BAO_ARCH="amd64" ;;
  aarch64) BAO_ARCH="arm64" ;;
  *)       echo "Unsupported architecture: $ARCH"; exit 1 ;;
esac

NAME="openbao_${VERSION}_linux_${BAO_ARCH}.tar.gz"
BASE="https://github.com/openbao/openbao/releases/download/v${VERSION}"

curl -fsSL "${BASE}/${NAME}" -o /tmp/openbao.tar.gz

# Checksums are verified here and not in the other download features because this
# one hands out credentials. checksums.txt is the standard "<hash>  <name>" form,
# so only the filename needs rewriting to match what we saved.
curl -fsSL "${BASE}/checksums.txt" -o /tmp/openbao_checksums.txt
(cd /tmp && grep " ${NAME}\$" openbao_checksums.txt \
   | sed "s| ${NAME}| openbao.tar.gz|" | sha256sum -c - >/dev/null)

# The tarball holds bao plus CHANGELOG/LICENSE/README at its root; take the binary.
tar -xzf /tmp/openbao.tar.gz -C /usr/local/bin bao
chmod +x /usr/local/bin/bao
rm -f /tmp/openbao.tar.gz /tmp/openbao_checksums.txt

echo "Installed $(bao version)"
