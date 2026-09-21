#!/usr/bin/env bash
set -e

ARCH=$(uname -m)
case "$ARCH" in
  x86_64)  PS_ARCH="x64" ;;
  aarch64) PS_ARCH="arm64" ;;
  *)       echo "Unsupported architecture: $ARCH"; exit 1 ;;
esac

# pwsh will not start without ICU, and that is ~135 MB -- most of the cost of this
# feature after pwsh itself. Debian renames the runtime package every release
# (libicu72, libicu74, ...), so pick whatever this base actually carries.
if command -v dnf >/dev/null 2>&1; then
  dnf -y --setopt=install_weak_deps=False install libicu
  dnf clean all; rm -rf /var/cache/dnf /var/cache/libdnf5
elif command -v microdnf >/dev/null 2>&1; then
  microdnf -y --setopt=install_weak_deps=False install libicu
  microdnf clean all; rm -rf /var/cache/dnf /var/cache/libdnf5
elif command -v apt-get >/dev/null 2>&1; then
  export DEBIAN_FRONTEND=noninteractive
  apt-get update -y
  ICU_PKG=$(apt-cache search --names-only '^libicu[0-9]+$' | cut -d' ' -f1 | sort -V | tail -1)
  apt-get install -y --no-install-recommends "${ICU_PKG:-libicu-dev}"
  rm -rf /var/lib/apt/lists/*
else
  echo "No supported package manager; cannot install ICU, which pwsh requires" >&2
  exit 1
fi

NAME="powershell-${VERSION}-linux-${PS_ARCH}.tar.gz"
BASE="https://github.com/PowerShell/PowerShell/releases/download/v${VERSION}"

curl -fsSL "${BASE}/${NAME}" -o /tmp/pwsh.tar.gz

# hashes.sha256 is UTF-16LE with a BOM and CRLF endings -- sha256sum cannot read
# it as published. Re-encode, drop the CR, then rewrite the filename to match what
# we saved. The "*" separator is kept: coreutils reads it as binary mode.
curl -fsSL "${BASE}/hashes.sha256" -o /tmp/pwsh_hashes.utf16
iconv -f UTF-16 -t UTF-8 /tmp/pwsh_hashes.utf16 | tr -d '\r' > /tmp/pwsh_hashes.txt
(cd /tmp && grep "\*${NAME}\$" pwsh_hashes.txt \
   | sed "s|\*${NAME}|*pwsh.tar.gz|" | sha256sum -c - >/dev/null)

# The tarball has no top-level directory, so it needs its own target.
PS_HOME=/opt/microsoft/powershell/7
mkdir -p "$PS_HOME"
tar -xzf /tmp/pwsh.tar.gz -C "$PS_HOME"
chmod +x "$PS_HOME/pwsh"
ln -sf "$PS_HOME/pwsh" /usr/bin/pwsh
rm -f /tmp/pwsh.tar.gz /tmp/pwsh_hashes.utf16 /tmp/pwsh_hashes.txt

if [ "${INSTALLPSSCRIPTANALYZER}" = "true" ]; then
  # AllUsers, so it resolves for every user rather than only whoever built.
  pwsh -NoLogo -NoProfile -Command \
    "Set-PSRepository PSGallery -InstallationPolicy Trusted; \
     Install-Module PSScriptAnalyzer -Scope AllUsers -Force -ErrorAction Stop"
  echo "Installed PSScriptAnalyzer $(pwsh -NoLogo -NoProfile -Command '(Get-Module -ListAvailable PSScriptAnalyzer).Version.ToString()')"
fi

echo "Installed PowerShell $(pwsh -NoLogo -NoProfile -Command '$PSVersionTable.PSVersion.ToString()')"
