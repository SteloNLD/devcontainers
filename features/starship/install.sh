#!/usr/bin/env bash
set -e

ARCH=$(uname -m)
case "$ARCH" in
  x86_64)  STARSHIP_ARCH="x86_64" ;;
  aarch64) STARSHIP_ARCH="aarch64" ;;
  *)       echo "Unsupported architecture: $ARCH"; exit 1 ;;
esac

# musl, so the binary does not care whether the base is Debian or Fedora.
TARBALL="starship-${STARSHIP_ARCH}-unknown-linux-musl.tar.gz"
BASE="https://github.com/starship/starship/releases/download/v${VERSION}"

curl -fsSL "${BASE}/${TARBALL}" -o /tmp/starship.tar.gz

# The published .sha256 is a bare hash with no filename, so `sha256sum -c` cannot
# consume it directly -- build the check line here instead.
EXPECTED=$(curl -fsSL "${BASE}/${TARBALL}.sha256")
echo "${EXPECTED}  /tmp/starship.tar.gz" | sha256sum -c - >/dev/null

# The tarball holds a single `starship` binary at its root.
tar -xzf /tmp/starship.tar.gz -C /usr/local/bin starship
chmod +x /usr/local/bin/starship
rm /tmp/starship.tar.gz

if [ "${INSTALLSHELLHOOK}" = "true" ]; then
  # Same distro split as the direnv feature, and for the same reason -- getting it
  # wrong fails silently, leaving the stock distro prompt with no error anywhere.
  #   Debian/Ubuntu: interactive non-login bash reads /etc/bash.bashrc, and that
  #                  file does NOT source /etc/profile.d.
  #   Fedora/RHEL:   there is no /etc/bash.bashrc; /etc/bashrc sources
  #                  /etc/profile.d/*.sh for interactive non-login shells too.
  #
  # Guarded on STARSHIP_SHELL, which `starship init bash` exports. A dotfiles repo
  # that also initialises starship will then skip its own eval rather than install
  # the PROMPT_COMMAND and DEBUG trap twice.
  HOOK='[ -z "${STARSHIP_SHELL:-}" ] && eval "$(starship init bash)"'
  if [ -f /etc/bash.bashrc ]; then
    echo "$HOOK" >> /etc/bash.bashrc
    HOOK_TARGET=/etc/bash.bashrc
  elif [ -d /etc/profile.d ]; then
    echo "$HOOK" > /etc/profile.d/starship.sh
    chmod +x /etc/profile.d/starship.sh
    HOOK_TARGET=/etc/profile.d/starship.sh
  else
    echo "Could not find a shell startup file to hook starship into" >&2
    exit 1
  fi
  echo "Installed $(starship --version | head -1), hooked via ${HOOK_TARGET}"
else
  echo "Installed $(starship --version | head -1), no shell hook (installShellHook=false)"
fi
