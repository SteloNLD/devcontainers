#!/usr/bin/env bash
set -e

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
