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

VERSION=$(resolve_version "${VERSION}" "https://github.com/PowerShell/PowerShell")
[ -n "$VERSION" ] || { echo "Could not resolve a version from https://github.com/PowerShell/PowerShell" >&2; exit 1; }

ARCH=$(uname -m)
case "$ARCH" in
  x86_64)  PS_ARCH="x64" ;;
  aarch64) PS_ARCH="arm64" ;;
  *)       echo "Unsupported architecture: $ARCH"; exit 1 ;;
esac

# pwsh will not start without ICU at all -- it FailFasts with "Couldn't find a
# valid ICU package installed on the system". That is ~135 MB, most of this
# feature's cost after pwsh itself, which is why it can be dropped again below.
#
# Whether we installed it matters: on a base that already had ICU, something else
# may be linking it, and removing it would cascade through dnf's dependents.
if command -v dnf >/dev/null 2>&1; then
  MGR=dnf
elif command -v microdnf >/dev/null 2>&1; then
  MGR=microdnf
elif command -v apt-get >/dev/null 2>&1; then
  MGR=apt-get
else
  echo "No supported package manager; cannot install ICU, which pwsh requires" >&2
  exit 1
fi

ICU_WAS_PRESENT=false
case "$MGR" in
  dnf|microdnf)
    ICU_PKG=libicu
    rpm -q "$ICU_PKG" >/dev/null 2>&1 && ICU_WAS_PRESENT=true
    $MGR -y --setopt=install_weak_deps=False install "$ICU_PKG"
    $MGR clean all; rm -rf /var/cache/dnf /var/cache/libdnf5
    ;;
  apt-get)
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -y
    # Debian renames the runtime package every release (libicu72, libicu74, ...),
    # so take the newest one this base actually carries.
    ICU_PKG=$(apt-cache search --names-only '^libicu[0-9]+$' | cut -d' ' -f1 | sort -V | tail -1)
    ICU_PKG=${ICU_PKG:-libicu-dev}
    dpkg -s "$ICU_PKG" >/dev/null 2>&1 && ICU_WAS_PRESENT=true
    apt-get install -y --no-install-recommends "$ICU_PKG"
    rm -rf /var/lib/apt/lists/*
    ;;
esac

PS_HOME=/opt/microsoft/powershell/7
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
mkdir -p "$PS_HOME"
tar -xzf /tmp/pwsh.tar.gz -C "$PS_HOME"
chmod +x "$PS_HOME/pwsh"
ln -sf "$PS_HOME/pwsh" /usr/bin/pwsh
rm -f /tmp/pwsh.tar.gz /tmp/pwsh_hashes.utf16 /tmp/pwsh_hashes.txt

if [ "${INSTALLPSSCRIPTANALYZER}" = "true" ]; then
  # Must happen while ICU is still present: PowerShellGet loads localized data
  # through the current culture, and in invariant mode Install-Module dies with
  # "The variable '$LocalizedData' cannot be retrieved because it has not been set".
  pwsh -NoLogo -NoProfile -Command \
    "Set-PSRepository PSGallery -InstallationPolicy Trusted; \
     Install-Module PSScriptAnalyzer -Scope AllUsers -Force -ErrorAction Stop"
  echo "Installed PSScriptAnalyzer $(pwsh -NoLogo -NoProfile -Command '(Get-Module -ListAvailable PSScriptAnalyzer).Version.ToString()')"

  if [ "${INCLUDECOMPATIBILITYPROFILES}" != "true" ]; then
    # 279 of the module's 286 MB is compatibility_profiles: JSON dumps of the API
    # surface of assorted Windows PowerShell builds, read only by the
    # PSUseCompatible* rules. Those rules emit nothing until you hand them target
    # profiles, so on a Linux IaC box this is the single largest dead weight in
    # the image. Verified: lint output is identical with and without them.
    PROFILES=$(find /usr/local/share/powershell/Modules/PSScriptAnalyzer \
                 -maxdepth 2 -type d -name compatibility_profiles 2>/dev/null)
    if [ -n "$PROFILES" ]; then
      rm -rf $PROFILES
      echo "Dropped PSScriptAnalyzer compatibility_profiles (~279 MB)."
    fi
  fi
fi

if [ "${USEINVARIANTGLOBALIZATION}" = "true" ]; then
  # Set in pwsh's own runtimeconfig rather than via DOTNET_SYSTEM_GLOBALIZATION_INVARIANT,
  # because the editor extension spawns pwsh itself and an env var only reaches it if
  # whatever launched VS Code happened to export one. This travels with the install.
  pwsh -NoLogo -NoProfile -Command "
    \$p = '${PS_HOME}/pwsh.runtimeconfig.json'
    \$j = Get-Content \$p -Raw | ConvertFrom-Json
    \$j.runtimeOptions.configProperties |
      Add-Member -NotePropertyName 'System.Globalization.Invariant' -NotePropertyValue \$true -Force
    \$j | ConvertTo-Json -Depth 20 | Set-Content \$p"

  # Only remove ICU if this feature is what put it there; on a base that already
  # had it, something else may be linking it and dnf would cascade the removal.
  if [ "$ICU_WAS_PRESENT" = "false" ]; then
    case "$MGR" in
      dnf|microdnf) $MGR -y remove $ICU_PKG; $MGR -y autoremove; $MGR clean all
                    rm -rf /var/cache/dnf /var/cache/libdnf5 ;;
      apt-get)      apt-get purge -y "$ICU_PKG"; apt-get autoremove -y
                    rm -rf /var/lib/apt/lists/* ;;
    esac
    echo "Removed ${ICU_PKG} (~135 MB); pwsh runs with invariant globalization."
  else
    echo "Invariant globalization enabled; left ${ICU_PKG} alone (it predates this feature)."
  fi
fi

echo "Installed PowerShell $(pwsh -NoLogo -NoProfile -Command '$PSVersionTable.PSVersion.ToString()')"
