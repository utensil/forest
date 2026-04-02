# Mattermost Stack

Self-hosted Mattermost (Team Edition) with PostgreSQL, designed for a two-node
primary/standby setup across macOS hosts (mimi + clawlet) running Colima Docker.

## Architecture

```
Tailscale (phone / laptop)
        |
        | :8065  (via Tailscale IP of the VM)
        ▼
macOS VM  ──nginx reverse proxy──▶  192.168.64.1:8065
                                            |
                                     macOS HOST (Colima)
                                      ┌────────────────┐
                                      │  mattermost    │
                                      │  postgres:5432 │
                                      └────────────────┘

Two hosts: mimi (primary) and clawlet (standby).
PostgreSQL streaming replication is tunnelled over SSH between the two VMs.
```

## Steps

### Step 1 — mimi host: first run

```bash
# On mimi macOS HOST (Colima must be running)
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

Open `http://192.168.64.1:8065` from the mimi macOS VM to complete the Setup Wizard.

### Step 2 — mimi VM: nginx reverse proxy for Tailscale access

Install nginx on the mimi macOS VM and proxy Tailscale IP → HOST bridge:

```nginx
# /etc/nginx/conf.d/mattermost.conf  (or Homebrew nginx equivalent)
server {
    listen <MIMI_TAILSCALE_IP>:8065;
    location / {
        proxy_pass http://192.168.64.1:8065;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_read_timeout 600s;
    }
}
```

Access from phone/laptop: `http://<MIMI_TAILSCALE_IP>:8065`

### Step 3 — clawlet host: second node

Same as Step 1 on clawlet's HOST, but set `POSTGRES_ROLE=standby` in `.env`
and use the clawlet Tailscale IP in `MM_SERVICESETTINGS_SITEURL`.

> **Note:** On the standby node, start only postgres first (comment out the
> mattermost service). PostgreSQL streaming replication must be set up before
> starting Mattermost on the standby.

### Step 4 — Set up PostgreSQL streaming replication

#### On mimi VM: open a reverse SSH tunnel so clawlet can reach mimi's PG

```bash
# Run on mimi macOS VM (keep alive, or add to launchd)
ssh -N -R 0.0.0.0:5433:192.168.64.1:5432 lume@<CLAWLET_TAILSCALE_IP> \
  -o ServerAliveInterval=10 -o ExitOnForwardFailure=yes
```

This exposes mimi's PG as `localhost:5433` on clawlet VM (and its HOST via bridge).

#### On clawlet HOST: base backup from mimi

```bash
# Inside clawlet's postgres container (or via docker exec)
docker exec -it mattermost-postgres bash

# Stop postgres, wipe data, take base backup from mimi primary
pg_ctl stop -D "$PGDATA"
rm -rf "$PGDATA"/*

PGPASSWORD=<POSTGRES_REPLICATION_PASSWORD> \
  pg_basebackup -h 192.168.64.1 -p 5433 -U replicator \
    -D "$PGDATA" -Fp -Xs -P -R
# -R writes standby.signal + primary_conninfo automatically

pg_ctl start -D "$PGDATA"
```

Verify replication:
```sql
-- On mimi primary
SELECT client_addr, state, sent_lsn, write_lsn, flush_lsn, replay_lsn
FROM pg_stat_replication;
```

### Step 5 — Failover & pg_rewind

#### Promote clawlet standby to primary

```bash
docker exec mattermost-postgres pg_ctl promote -D "$PGDATA"
```

Then update `.env` on clawlet: `POSTGRES_ROLE=primary` and restart Mattermost.

#### Rejoin old primary (mimi) as new standby using pg_rewind

```bash
# On mimi HOST, after clawlet is new primary:
docker exec -it mattermost-postgres bash

pg_ctl stop -D "$PGDATA"
PGPASSWORD=<POSTGRES_REPLICATION_PASSWORD> \
  pg_rewind \
    --target-pgdata="$PGDATA" \
    --source-server="host=192.168.64.1 port=5433 user=replicator dbname=postgres" \
    -P

# Write standby.signal and update primary_conninfo
touch "$PGDATA/standby.signal"
cat >> "$PGDATA/postgresql.conf" <<EOF
primary_conninfo = 'host=192.168.64.1 port=5433 user=replicator password=<REPL_PW>'
EOF

pg_ctl start -D "$PGDATA"
```

## Ports

| Service    | Container port | Host port (configurable) |
|------------|---------------|--------------------------|
| Mattermost | 8065          | `APP_PORT` (default 8065)|
| Mattermost calls | 8443   | `CALLS_PORT` (default 8443)|
| PostgreSQL | 5432          | `POSTGRES_PORT` (default 5432)|

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
  from the macOS HOST via the bridge (`192.168.64.1`). Use `pf` if you want to
  restrict it further (see kopia sstore lesson).
- Mattermost port (`8065`) is similarly only accessible via bridge from the VM;
  the VM's nginx reverse proxy controls Tailscale exposure.
- Change all default passwords in `.env` before first run.
