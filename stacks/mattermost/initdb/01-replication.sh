#!/bin/bash
# Runs once on first DB init (inside the postgres container).
# Creates a dedicated replication user and enables WAL for streaming replication.
# This script is only needed on the primary node.
set -e

# Require the replication password to be explicitly set — no insecure fallback.
if [ -z "$POSTGRES_REPLICATION_PASSWORD" ]; then
    echo "ERROR: POSTGRES_REPLICATION_PASSWORD must be set before first DB init." >&2
    exit 1
fi

# Create the replication role via createuser + ALTER ROLE to avoid
# embedding the password as a SQL string literal (single-quote injection risk).
createuser --username "$POSTGRES_USER" --replication replicator 2>/dev/null || true

# Set password separately using PGPASSWORD env var so no quoting issues.
PGPASSWORD="$POSTGRES_REPLICATION_PASSWORD" \
    psql -v ON_ERROR_STOP=1 \
         --username "$POSTGRES_USER" \
         --dbname "$POSTGRES_DB" \
         --no-password \
         -c "ALTER ROLE replicator WITH LOGIN PASSWORD \$repl_pw\$${POSTGRES_REPLICATION_PASSWORD}\$repl_pw\$;"

# Restrict replication connections to localhost only (tunnel arrives on loopback).
# Adjust the CIDR if your tunnel setup uses a different source address.
cat >> "$PGDATA/pg_hba.conf" <<-EOF

# Allow streaming replication from localhost only (SSH tunnel termination point).
# The standby connects via an SSH reverse tunnel that arrives on 127.0.0.1.
host    replication     replicator      127.0.0.1/32    scram-sha-256
EOF

# Enable WAL streaming replication in postgresql.conf.
cat >> "$PGDATA/postgresql.conf" <<-EOF

# Streaming replication -- primary settings
wal_level = replica
max_wal_senders = 5
wal_keep_size = 256MB
hot_standby = on
EOF
