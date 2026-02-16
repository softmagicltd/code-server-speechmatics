#!/bin/sh
set -eu

PORT="${PORT:-8080}"
DATA_DIR="${DATA_DIR:-/home/coder/data}"
CS_CONFIG_DIR="${DATA_DIR}/.config/code-server"
CS_CONFIG="${CS_CONFIG_DIR}/config.yaml"

# Ensure persistent data directory exists and is owned by coder (UID 1000).
# Railway volumes are created as root, so fix ownership on first run.
mkdir -p "${DATA_DIR}"
mkdir -p "${CS_CONFIG_DIR}"
chown -R 1000:1000 "${DATA_DIR}"

# --- Password setup ---
# Priority:
#   1. HASHED_PASSWORD env var (pre-hashed, Argon2 or SHA-256)
#   2. PASSWORD env var (plain text, used directly by code-server)
#   3. Existing config file password
#   4. Error: no password configured

if [ -n "${HASHED_PASSWORD:-}" ]; then
  echo "Using pre-hashed password from HASHED_PASSWORD env var."
  cat > "${CS_CONFIG}" <<EOF
bind-addr: 0.0.0.0:${PORT}
auth: password
hashed-password: "${HASHED_PASSWORD}"
cert: false
EOF
elif [ -n "${PASSWORD:-}" ]; then
  echo "Using password from PASSWORD env var."
  cat > "${CS_CONFIG}" <<EOF
bind-addr: 0.0.0.0:${PORT}
auth: password
password: ${PASSWORD}
cert: false
EOF
elif [ -f "${CS_CONFIG}" ]; then
  echo "Using existing config at ${CS_CONFIG}."
  # Update bind-addr in existing config to match Railway's PORT
  if command -v sed >/dev/null 2>&1; then
    sed -i "s|^bind-addr:.*|bind-addr: 0.0.0.0:${PORT}|" "${CS_CONFIG}"
  fi
else
  echo "ERROR: No password configured."
  echo ""
  echo "Set one of the following environment variables:"
  echo "  PASSWORD=your-password          (plain text)"
  echo "  HASHED_PASSWORD='\$argon2...'    (pre-hashed with Argon2)"
  echo ""
  echo "To generate a hashed password, run:"
  echo "  docker exec <container> set-password your-new-password"
  exit 1
fi

# Point code-server config at our persistent location
export XDG_CONFIG_HOME="${DATA_DIR}/.config"

# Drop to coder (UID 1000) and launch code-server
exec su coder -c "exec dumb-init /usr/bin/code-server \
  --config '${CS_CONFIG}' \
  --user-data-dir '${DATA_DIR}/user-data' \
  --extensions-dir '${DATA_DIR}/extensions' \
  --bind-addr '0.0.0.0:${PORT}' \
  '${DATA_DIR}/workspace'"
