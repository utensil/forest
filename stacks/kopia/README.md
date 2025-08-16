# Kopia Backup Stack

This stack provides a Kopia backup server running in Docker, with web UI and API access on port 51515.

## Usage

1. Copy `.env.in` to `.env` and fill in your secrets and paths:

    ```sh
    cp .env.in .env
     # Edit .env to set KOPIA_PASSWORD, KOPIA_USER, KOPIA_SERVER_USER, KOPIA_SERVER_PASSWORD, PODS_HOME, DATA_SRC, DATA_DST
    ```

2. Create the required directories under your `$PODS_HOME`:

    ```sh
     mkdir -p $PODS_HOME/kopia/{config,cache,logs,data,repository,tmp}
    ```

3. Start the stack:

    ```sh
    docker-compose -f compose.yaml up -d
    ```

4. Access the Kopia web UI at:
    - http://localhost:51515 (direct, not proxied)
    - https://kopia.homelab.local (via Caddy reverse proxy, with internal TLS)
    - Login with `${KOPIA_SERVER_USER}` and `${KOPIA_SERVER_PASSWORD}`

## Volumes

-   `${PODS_HOME}/kopia/config` → `/app/config` (Kopia config)
-   `${PODS_HOME}/kopia/cache` → `/app/cache` (Kopia cache)
-   `${PODS_HOME}/kopia/logs` → `/app/logs` (Kopia logs)
-   `${PODS_HOME}/kopia/tmp` → `/tmp:shared` (For browsing mounted snapshots)
-   `${DATA_SRC}` → `/mnt/src` (Source data, read-only)
-   `${DATA_DST}` → `/mnt/dst` (Destination data, writable)

## Environment Variables

-   `KOPIA_PASSWORD`: Password for the Kopia repository
-   `KOPIA_USER`: User for the container (optional, for logs/ownership)
-   `KOPIA_SERVER_USER`: Username for the web UI/API
-   `KOPIA_SERVER_PASSWORD`: Password for the web UI/API
-   `PODS_HOME`: Base directory for persistent data/volumes
-   `DATA_SRC`: Path to source data (read-only mount at /mnt/src)
-   `DATA_DST`: Path to destination data (writable mount at /mnt/dst)

## References

-   [Kopia Docker Docs](https://kopia.io/docs/installation/#docker-images)
-   [Official docker-compose example](https://github.com/kopia/kopia/blob/master/tools/docker/docker-compose.yml)

---

AGENT-NOTE: This stack follows project conventions for compose, .env, and volume layout. Update as needed for your backup sources.
