#!/usr/bin/env bash
set -euo pipefail
: "${APT_GPG_PRIVATE_KEY:?Set APT_GPG_PRIVATE_KEY GitHub Actions secret}"
for cmd in dpkg-scanpackages apt-ftparchive dpkg-deb gpg; do
  command -v "$cmd" >/dev/null || { echo "Missing command: $cmd" >&2; exit 1; }
done
shopt -s nullglob
files=(dist/*.deb)
(( ${#files[@]} == 4 )) || { echo "Expected exactly 4 packages; got ${#files[@]}" >&2; exit 1; }
mkdir -p site/pool/noble/main site/pool/resolute/main
: > site/.nojekyll
for deb in "${files[@]}"; do
  package="$(dpkg-deb -f "$deb" Package)"
  arch="$(dpkg-deb -f "$deb" Architecture)"
  version="$(dpkg-deb -f "$deb" Version)"
  [[ "$package" == 'hermes-desktop-light' && ( "$arch" == amd64 || "$arch" == arm64 ) ]] || {
    echo "Unexpected deb metadata: $deb" >&2; exit 1;
  }
  case "$version" in
    *+ubuntu24.04) suite=noble ;;
    *+ubuntu26.04) suite=resolute ;;
    *) echo "Unknown Ubuntu target: $version" >&2; exit 1 ;;
  esac
  cp "$deb" "site/pool/$suite/main/"
done
export GNUPGHOME="$(mktemp -d)"
chmod 700 "$GNUPGHOME"
trap 'rm -rf "$GNUPGHOME"' EXIT
printf '%s\n' "$APT_GPG_PRIVATE_KEY" | gpg --batch --quiet --import
fingerprint="$(gpg --batch --with-colons --list-secret-keys | awk -F: '$1 == "fpr" { print $10; exit }')"
[[ -n "$fingerprint" ]] || { echo 'Signing key unavailable' >&2; exit 1; }
gpg --batch --export --output site/hermes-desktop-light.gpg "$fingerprint"
gpg --batch --armor --export --output site/hermes-desktop-light.asc "$fingerprint"
for suite in noble resolute; do
  for arch in amd64 arm64; do
    repo_dir="site/dists/$suite/main/binary-$arch"
    mkdir -p "$repo_dir"
    (
      cd site
      dpkg-scanpackages --arch "$arch" "pool/$suite/main" /dev/null > "dists/$suite/main/binary-$arch/Packages"
      gzip -n -9 -c "dists/$suite/main/binary-$arch/Packages" > "dists/$suite/main/binary-$arch/Packages.gz"
    )
    [[ "$(grep -c '^Package: hermes-desktop-light$' "$repo_dir/Packages")" == '1' ]] || {
      echo "Expected exactly one $suite $arch package entry" >&2; exit 1;
    }
  done
  cat > site/release.conf <<CONF
APT::FTPArchive::Release::Origin "Hermes Desktop Light community";
APT::FTPArchive::Release::Label "Hermes Desktop Light community";
APT::FTPArchive::Release::Suite "$suite";
APT::FTPArchive::Release::Codename "$suite";
APT::FTPArchive::Release::Architectures "amd64 arm64";
APT::FTPArchive::Release::Components "main";
CONF
  ( cd site && apt-ftparchive -c release.conf release "dists/$suite" > "dists/$suite/Release" )
  gpg --batch --yes --local-user "$fingerprint" --clearsign -o "site/dists/$suite/InRelease" "site/dists/$suite/Release"
  gpg --batch --yes --local-user "$fingerprint" --armor --detach-sign -o "site/dists/$suite/Release.gpg" "site/dists/$suite/Release"
done
rm -f site/release.conf
( cd dist && sha256sum -- *.deb > SHA256SUMS )
printf 'Signed Ubuntu noble/resolute amd64/arm64 repositories ready in site/\n'
