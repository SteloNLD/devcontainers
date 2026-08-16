#!/usr/bin/env bash
set -e

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
