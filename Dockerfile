FROM codercom/code-server:latest

USER root

# Copy entrypoint and helper scripts
COPY docker/entrypoint.sh /usr/bin/railway-entrypoint.sh
COPY docker/set-password.sh /usr/local/bin/set-password
RUN chmod +x /usr/bin/railway-entrypoint.sh /usr/local/bin/set-password

# Railway injects PORT env var; default to 8080
ENV PORT=8080

# Persistent data directory (mount a Railway volume here)
ENV DATA_DIR=/home/coder/data

# Entrypoint runs as root to fix volume permissions, then drops to UID 1000
ENTRYPOINT ["/usr/bin/railway-entrypoint.sh"]
