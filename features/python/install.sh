#!/usr/bin/env bash
set -e

# Why this exists rather than devcontainers/features/python.
#
# Upstream can build CPython from source for any version you name. To keep that
# possible it installs a fixed development toolchain BEFORE it looks at the
# version option, so `version: os-provided` pays for a capability it never uses.
# On Fedora that list is:
#
#   gcc make bzip2-devel libffi-devel libxml2-devel ncurses-devel openssl-devel
#   sqlite-devel xz-devel zlib-devel tk-devel gdbm-devel readline-devel
#   uuid-devel xmlsec1-devel ...
#
# gcc alone is 120 MB, and tk-devel pulls libGL, which pulls Mesa, which pulls
# llvm-libs -- 140.5 MB of LLVM and 52.3 MB of DRI drivers in a container that
# will never render anything. Measured end to end: the image went 866 MB ->
# 1381 MB.
#
# So this feature does the one thing that was actually wanted: install the
# distro's python. No compiler, no headers, no source builds.

PKGS="python3 python3-pip"
[ "${INSTALLPIPX}" = "true" ] && PKGS="${PKGS} pipx"

if command -v dnf >/dev/null 2>&1; then
  MGR=dnf
elif command -v microdnf >/dev/null 2>&1; then
  MGR=microdnf
elif command -v apt-get >/dev/null 2>&1; then
  MGR=apt-get
else
  echo "No supported package manager found (dnf, microdnf, apt-get)" >&2
  exit 1
fi

# Clean inside this layer. A feature is its own layer, so the base image's own
# `dnf clean all` does nothing for the cache created here.
case "$MGR" in
  dnf|microdnf)
    $MGR -y --setopt=install_weak_deps=False install $PKGS
    $MGR clean all
    rm -rf /var/cache/dnf /var/cache/libdnf5
    ;;
  apt-get)
    # Debian splits pipx out and names venv separately; --no-install-recommends
    # is the apt equivalent of install_weak_deps=False.
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -y
    apt-get install -y --no-install-recommends $PKGS python3-venv
    rm -rf /var/lib/apt/lists/*
    ;;
esac

echo "Installed $(python3 --version) and $(pip3 --version | cut -d' ' -f1-2) via ${MGR}"
[ "${INSTALLPIPX}" = "true" ] && echo "pipx: $(pipx --version 2>/dev/null || echo 'not on PATH yet')"
exit 0
