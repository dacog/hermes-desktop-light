#!/usr/bin/env bash
set -euo pipefail
# Generate once on your trusted machine. Never commit signing/.
mkdir -p signing
chmod 700 signing
export GNUPGHOME="$(mktemp -d)"
chmod 700 "$GNUPGHOME"
trap 'rm -rf "$GNUPGHOME"' EXIT
gpg --batch --pinentry-mode loopback --passphrase '' --quick-generate-key \
  'Hermes Desktop Light Community APT <apt@example.invalid>' rsa4096 sign 0
fingerprint="$(gpg --with-colons --list-secret-keys | awk -F: '$1 == "fpr" { print $10; exit }')"
gpg --armor --export-secret-keys "$fingerprint" > signing/apt-private-key.asc
gpg --armor --export "$fingerprint" > signing/apt-public-key.asc
chmod 600 signing/apt-private-key.asc
printf 'Fingerprint: %s\n' "$fingerprint"
printf 'Next: gh secret set APT_GPG_PRIVATE_KEY < signing/apt-private-key.asc\n'
printf 'IMPORTANT: back up the key and NEVER commit signing/.\n'
