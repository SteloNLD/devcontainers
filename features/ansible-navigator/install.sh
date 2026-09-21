#!/usr/bin/env bash
set -e

# onigurumacffi has no linux aarch64 wheel (the arm64 wheels on PyPI are macOS),
# so arm64 builds it from sdist against oniguruma -- and our python feature ships
# no compiler. Toolchain goes in for the build and comes back out (~200 MB).
if command -v dnf >/dev/null 2>&1; then
  MGR=dnf
elif command -v microdnf >/dev/null 2>&1; then
  MGR=microdnf
elif command -v apt-get >/dev/null 2>&1; then
  MGR=apt-get
else
  MGR=""
fi

case "$MGR" in
  dnf|microdnf) ONIG_RUNTIME="oniguruma"; ONIG_BUILD="gcc python3-devel libffi-devel oniguruma-devel" ;;
  apt-get)      ONIG_RUNTIME="libonig5";  ONIG_BUILD="gcc python3-dev libffi-dev libonig-dev" ;;
  *)            ONIG_RUNTIME="";          ONIG_BUILD="" ;;
esac

# No pipe: it would hand `if` the exit status of the pipeline's last command.
have_wheel() {
  python3 -m pip download --only-binary=:all: --no-deps --no-cache-dir \
    --dest /tmp/onig-probe 'onigurumacffi<2,>=1.1.0' >/dev/null 2>&1
}

BUILT_FROM_SOURCE=false
if [ -n "$MGR" ] && ! have_wheel; then
  BUILT_FROM_SOURCE=true
  echo "No onigurumacffi wheel for $(uname -m); building it from source."
  case "$MGR" in
    dnf|microdnf)
      # Runtime lib in its own transaction first, so it is marked user-installed.
      # Pulled in as a dep of -devel instead, the autoremove below deletes it and
      # navigator breaks at `from .action_runner import ActionRunner`.
      $MGR -y --setopt=install_weak_deps=False install $ONIG_RUNTIME
      $MGR -y --setopt=install_weak_deps=False install $ONIG_BUILD
      ;;
    apt-get)
      export DEBIAN_FRONTEND=noninteractive
      apt-get update -y
      apt-get install -y --no-install-recommends $ONIG_RUNTIME
      apt-get install -y --no-install-recommends $ONIG_BUILD
      ;;
  esac
fi
rm -rf /tmp/onig-probe

# --include-deps also exposes ansible, ansible-playbook, ansible-galaxy and
# ansible-lint from this venv, so no separate ansible install is needed.
pipx install --include-deps ansible-navigator

if [ "$BUILT_FROM_SOURCE" = "true" ]; then
  echo "Removing the build toolchain; $ONIG_RUNTIME stays for the built extension."
  case "$MGR" in
    dnf|microdnf)
      $MGR -y remove $ONIG_BUILD
      $MGR -y autoremove
      $MGR clean all
      rm -rf /var/cache/dnf /var/cache/libdnf5
      ;;
    apt-get)
      apt-get purge -y $ONIG_BUILD
      apt-get autoremove -y
      rm -rf /var/lib/apt/lists/*
      ;;
  esac
fi

echo "Installed $(ansible-navigator --version)"
echo "Exposed   $(ansible --version | head -1)"
echo "Exposed   $(ansible-lint --version | head -1)"
