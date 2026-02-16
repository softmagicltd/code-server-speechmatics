#!/bin/sh
set -eu

# Generates an Argon2 hash for use with code-server.
#
# Usage:
#   set-password <new-password>
#   set-password                  (prompts interactively)
#
# The output hash can be used as:
#   - The HASHED_PASSWORD environment variable on Railway
#   - The hashed-password field in config.yaml

DATA_DIR="${DATA_DIR:-/home/coder/data}"
CS_CONFIG_DIR="${DATA_DIR}/.config/code-server"
CS_CONFIG="${CS_CONFIG_DIR}/config.yaml"

if [ $# -ge 1 ]; then
  NEW_PASSWORD="$1"
else
  printf "Enter new password: "
  stty -echo 2>/dev/null || true
  read -r NEW_PASSWORD
  stty echo 2>/dev/null || true
  echo ""

  printf "Confirm password: "
  stty -echo 2>/dev/null || true
  read -r CONFIRM_PASSWORD
  stty echo 2>/dev/null || true
  echo ""

  if [ "${NEW_PASSWORD}" != "${CONFIRM_PASSWORD}" ]; then
    echo "ERROR: Passwords do not match." >&2
    exit 1
  fi
fi

if [ -z "${NEW_PASSWORD}" ]; then
  echo "ERROR: Password cannot be empty." >&2
  exit 1
fi

# Use code-server's bundled argon2 to hash the password
CS_DIR=$(dirname "$(dirname "$(readlink -f "$(which code-server)")")")
HASHED=$(cd "${CS_DIR}" && node -e "
const argon2 = require('argon2');
argon2.hash(process.argv[1]).then(h => console.log(h));
" "${NEW_PASSWORD}")

echo ""
echo "Hashed password (Argon2):"
echo "${HASHED}"
echo ""

# Update config file if it exists
if [ -f "${CS_CONFIG}" ]; then
  printf "Update config file at %s? [y/N] " "${CS_CONFIG}"
  read -r REPLY
  if [ "${REPLY}" = "y" ] || [ "${REPLY}" = "Y" ]; then
    if grep -q "^hashed-password:" "${CS_CONFIG}"; then
      sed -i "s|^hashed-password:.*|hashed-password: \"${HASHED}\"|" "${CS_CONFIG}"
    elif grep -q "^password:" "${CS_CONFIG}"; then
      sed -i "s|^password:.*|hashed-password: \"${HASHED}\"|" "${CS_CONFIG}"
    else
      echo "hashed-password: \"${HASHED}\"" >> "${CS_CONFIG}"
    fi
    echo "Config updated. Restart code-server for changes to take effect."
  fi
fi

echo ""
echo "To use on Railway, set this environment variable:"
echo "  HASHED_PASSWORD=${HASHED}"
