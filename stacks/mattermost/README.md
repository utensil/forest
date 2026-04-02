# Mattermost Stack

Self-hosted Mattermost (Team Edition) with PostgreSQL, designed for a two-node
primary/standby setup across two macOS hosts running Colima Docker.

## Architecture

```
Tailscale (phone / laptop)
        |
        | :8065  (via Tailscale IP of the VM)
        ▼
macOS VM  ──nginx reverse proxy──▶  <HOST_BRIDGE_IP>:8065
                                            |
                                     macOS HOST (Colima)
                                      ┌────────────────┐
                                      │  mattermost    │
                                      │  postgres:5432 │
                                      └────────────────┘

Two hosts: node-a (primary) and node-b (standby).
PostgreSQL streaming replication is tunnelled over SSH between the two VMs.
```

## Steps

### Step 1 — node-a host: first run

```bash
# On the primary macOS HOST (Colima must be running)
cd ~/projects/forest/stacks/mattermost
cp .env.example .env
# Edit .env: set POSTGRES_PASSWORD, POSTGRES_REPLICATION_PASSWORD, MM_SERVICESETTINGS_SITEURL

# Create volume directories
mkdir -p volumes/db/var/lib/postgresql/data
mkdir -p volumes/app/mattermost/{config,data,logs,plugins,client/plugins,bleve-indexes}

# Fix permissions (Mattermost runs as uid 2000 inside container)
sudo chown -R 2000:2000 volumes/app/mattermost

docker compose up -d
docker compose logs -f
```

Open `http://<HOST_BRIDGE_IP>:8065` from the macOS VM to complete the Setup Wizard.

### Step 2 — node-a VM: nginx reverse proxy for Tailscale access

Install nginx on the macOS VM and proxy Tailscale IP → HOST bridge:

```nginx
# /etc/nginx/conf.d/mattermost.conf  (or Homebrew nginx equivalent)
server {
    listen <NODE_A_TAILSCALE_IP>:8065;
    location / {
        proxy_pass http://<HOST_BRIDGE_IP>:8065;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_read_timeout 600s;
    }
}
```

Access from phone/laptop: `http://<NODE_A_TAILSCALE_IP>:8065`

### Step 3 — node-b host: second node

Same as Step 1 on the standby HOST, but set `POSTGRES_ROLE=standby` in `.env`
and use the node-b Tailscale IP in `MM_SERVICESETTINGS_SITEURL`.

> **Note:** On the standby node, start only postgres first (comment out the
> mattermost service). PostgreSQL streaming replication must be set up before
> starting Mattermost on the standby.

### Step 4 — Set up PostgreSQL streaming replication

#### On node-a VM: open a reverse SSH tunnel so node-b can reach node-a's PG

```bash
# Run on node-a macOS VM (keep alive, or add to launchd)
ssh -N -R 0.0.0.0:5433:<HOST_BRIDGE_IP>:5432 <USER>@<NODE_B_TAILSCALE_IP> \
  -o ServerAliveInterval=10 -o ExitOnForwardFailure=yes
```

This exposes node-a's PG as `localhost:5433` on node-b VM (and its HOST via bridge).

#### On node-b HOST: base backup from node-a

```bash
# Inside node-b's postgres container (or via docker exec)
docker exec -it mattermost-postgres bash

# Stop postgres, wipe data, take base backup from node-a primary
pg_ctl stop -D "$PGDATA"
rm -rf "$PGDATA"/*

PGPASSWORD=<POSTGRES_REPLICATION_PASSWORD> \
  pg_basebackup -h <HOST_BRIDGE_IP> -p 5433 -U replicator \
    -D "$PGDATA" -Fp -Xs -P -R
# -R writes standby.signal + primary_conninfo automatically

pg_ctl start -D "$PGDATA"
```

Verify replication:
```sql
-- On node-a primary
SELECT client_addr, state, sent_lsn, write_lsn, flush_lsn, replay_lsn
FROM pg_stat_replication;
```

### Step 5 — Failover & pg_rewind

#### Promote node-b standby to primary

```bash
docker exec mattermost-postgres pg_ctl promote -D "$PGDATA"
```

Then update `.env` on node-b: `POSTGRES_ROLE=primary` and restart Mattermost.

#### Rejoin old primary (node-a) as new standby using pg_rewind

```bash
# On node-a HOST, after node-b is the new primary:
docker exec -it mattermost-postgres bash

pg_ctl stop -D "$PGDATA"
PGPASSWORD=<POSTGRES_REPLICATION_PASSWORD> \
  pg_rewind \
    --target-pgdata="$PGDATA" \
    --source-server="host=<HOST_BRIDGE_IP> port=5433 user=replicator dbname=postgres" \
    -P

# Write standby.signal and update primary_conninfo
touch "$PGDATA/standby.signal"
cat >> "$PGDATA/postgresql.conf" <<EOF
primary_conninfo = 'host=<HOST_BRIDGE_IP> port=5433 user=replicator password=<REPL_PW>'
EOF

pg_ctl start -D "$PGDATA"
```

## Ports

| Service          | Container port | Host port (configurable)      |
|------------------|---------------|-------------------------------|
| Mattermost       | 8065          | `APP_PORT` (default 8065)     |
| Mattermost calls | 8443          | `CALLS_PORT` (default 8443)   |
| PostgreSQL       | 5432          | `POSTGRES_PORT` (default 5432)|

## OpenClaw Integration

After Mattermost is running, install the OpenClaw plugin and configure each bot:

```bash
openclaw plugins install @openclaw/mattermost
```

Add to `~/.openclaw/openclaw.json`:
```json5
{
  channels: {
    mattermost: {
      enabled: true,
      botToken: "<bot-token>",
      baseUrl: "http://<VM_TAILSCALE_IP>:8065",
      chatmode: "oncall",
    }
  }
}
```

## Security notes

- PostgreSQL port (`5432`) is bound to `0.0.0.0` inside Colima but only reachable
  from the macOS HOST via the bridge (`<HOST_BRIDGE_IP>`). Use `pf` if you want to
  restrict it further (see kopia sstore lesson).
- Mattermost port (`8065`) is similarly only accessible via bridge from the VM;
  the VM's nginx reverse proxy controls Tailscale exposure.
- Change all default passwords in `.env` before first run.
