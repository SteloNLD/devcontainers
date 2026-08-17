#!/usr/bin/env bash
set -e

# Exists because upstream's devcontainers/features/github-cli is apt-only -- read
# its install.sh, there is no dnf or rpm path at all.
#
# Fedora packages gh, so on an RPM base this is just `dnf install gh` and the
# distro handles updates. The release-tarball path below is the fallback, so the
# feature still works on a base whose package manager does not carry gh -- which
# keeps it portable like the other features here, rather than trading one
# distro lock-in for another.

install_from_release() {
  local arch name base
  arch=$(uname -m)
  case "$arch" in
    x86_64)  arch="amd64" ;;
    aarch64) arch="arm64" ;;
    *) echo "Unsupported architecture: $(uname -m)"; exit 1 ;;
  esac

  name="gh_${VERSION}_linux_${arch}"
  base="https://github.com/cli/cli/releases/download/v${VERSION}"

  curl -fsSL "${base}/${name}.tar.gz" -o /tmp/gh.tar.gz

  # gh publishes one combined checksums file in the standard "<hash>  <name>"
  # form, so the line only needs its filename rewritten to match what we saved.
  curl -fsSL "${base}/gh_${VERSION}_checksums.txt" -o /tmp/gh_checksums.txt
  (cd /tmp && grep " ${name}.tar.gz\$" gh_checksums.txt \
     | sed "s| ${name}.tar.gz| gh.tar.gz|" | sha256sum -c - >/dev/null)

  # Unpacks to gh_<version>_linux_<arch>/{bin,share}; strip both leading
  # components so no versioned directory is left behind.
  tar -xzf /tmp/gh.tar.gz -C /usr/local/bin --strip-components=2 "${name}/bin/gh"
  chmod +x /usr/local/bin/gh

  if [ "${INSTALLMANPAGES}" = "true" ]; then
    mkdir -p /usr/local/share/man/man1
    tar -xzf /tmp/gh.tar.gz -C /usr/local/share/man/man1 --strip-components=4 "${name}/share/man/man1"
  fi

  rm -f /tmp/gh.tar.gz /tmp/gh_checksums.txt
  SOURCE="release tarball v${VERSION}"
}

install_from_dnf() {
  local mgr="$1"
  # Clean in the same layer -- a feature gets its own layer, so the base image's
  # `dnf clean all` does nothing for the cache this creates.
  "$mgr" -y --setopt=install_weak_deps=False install gh
  "$mgr" clean all
  rm -rf /var/cache/dnf /var/cache/libdnf5
  SOURCE="$mgr"
}

if [ "${USERELEASE}" = "true" ]; then
  install_from_release
elif command -v dnf >/dev/null 2>&1; then
  install_from_dnf dnf
elif command -v microdnf >/dev/null 2>&1; then
  install_from_dnf microdnf
else
  install_from_release
fi

echo "Installed $(gh --version | head -1) (via ${SOURCE})"
