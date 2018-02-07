#!/usr/bin/env bash
set -eu -o pipefail  # Abort on errors, disallow undefined variables
IFS=$'\n\t'          # Apply word splitting only on newlines and tabs

# Configure the Kurento package repository for `apt-get`.
#
# Changes:
# 2017-10-03 Juan Navarro <juan.navarro@gmx.es>
# - Initial version.

# Check root permissions
[ "$(id -u)" -eq 0 ] || { echo "Please run as root"; exit 1; }

# Settings
FILE="/etc/apt/sources.list.d/kurento.list"
REPO="xenial-dev"  # KMS development - Ubuntu 16.04 (Xenial)

tee "$FILE" >/dev/null <<EOF
# Packages for Kurento Media Server
deb http://ubuntu.kurento.org ${REPO} kms6
EOF

gpg --list-public-keys --no-default-keyring --keyring /etc/apt/trusted.gpg \
  --with-colons | grep -q "Kurento" && RC=$? || RC=$?

if [ "$RC" -eq 1 ]; then
  wget http://ubuntu.kurento.org/kurento.gpg.key -O - | apt-key add -
elif [ "$RC" -ne 0 ]; then
  echo "ERROR ($RC)"
  exit "$RC"
fi

apt-get update

echo "Repository '$REPO' configured at $FILE"

# ------------

echo ""
echo "[$0] Done."
