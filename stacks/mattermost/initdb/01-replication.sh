#!/bin/bash
# Runs once on first DB init (inside the postgres container).
# Creates a dedicated replication user so the standby can connect
# without using the superuser credentials.
set -e

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    -- Replication user (password set via PGPASSWORD or .pgpass on the standby)
    DO \$\$
    BEGIN
        IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'replicator') THEN
            CREATE ROLE replicator WITH REPLICATION LOGIN PASSWORD '${POSTGRES_REPLICATION_PASSWORD:-replicator_change_me}';
        END IF;
    END
    \$\$;
EOSQL

# Allow replication connections in pg_hba.conf
# (The official postgres image writes pg_hba.conf from POSTGRES_INITDB_ARGS;
#  we append here for clarity and reliability.)
cat >> "$PGDATA/pg_hba.conf" <<-EOF

# Allow streaming replication from any host using scram-sha-256
host    replication     replicator      0.0.0.0/0       scram-sha-256
EOF

# Enable WAL streaming replication settings in postgresql.conf
cat >> "$PGDATA/postgresql.conf" <<-EOF

# Streaming replication — primary settings
wal_level = replica
max_wal_senders = 5
wal_keep_size = 256MB      # keep 256 MB of WAL for lagging standbys
hot_standby = on           # allow read-only queries on standby
EOF
