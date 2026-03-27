# sstore — Secure SFTP Storage

A lightweight SFTP endpoint used as the storage backend for [Kopia](../kopia/) backup repositories.

Deploy one instance wherever storage lives:
- On a NAS (primary repository storage)
- On a host's external disk (replica storage)

Kopia connects to this container over SFTP using a dedicated keypair — no password auth, no internet exposure.

## Setup

1. Copy `.env.in` to `.env` and fill in values:

    ```sh
    cp .env.in .env
    # Edit .env: set STORAGE_PATH, SSTORE_LISTEN_ADDR, SSTORE_PORT, SSTORE_PUID/PGID
    ```

2. `STORAGE_PATH` should be the host path to the storage directory (NAS mount or external disk).
   The container mounts it at `/storage`.

3. `SSTORE_LISTEN_ADDR` controls which interface the port is bound to. `127.0.0.1` (loopback) is
   the default, but note that VMs on the same host **cannot** reach a loopback-bound port — if Kopia
   runs inside a VM, set this to the host-VM bridge IP for your environment. Never use `0.0.0.0`
   without a firewall.

4. `SSTORE_PUID`/`SSTORE_PGID` should match the owner of the files under `STORAGE_PATH`
   so files created by Kopia are owned correctly on the host.

5. Start:

    ```sh
    docker compose up -d
    ```

6. Create the persistent config directory (alongside your `.env`):

    ```sh
    mkdir -p config
    ```

   This directory is git-ignored and will hold `authorized_keys` and SSH host keys
   across container restarts. The default path is `./config` (relative to `compose.yaml`).
   Override with `SSTORE_CONFIG_PATH` in `.env` if needed.

7. Add authorized public keys for each Kopia host that needs access.
   Run this on the Docker host after the container is up:

    ```sh
    # Add one key at a time (repeat for each Kopia host)
    docker exec sstore sh -c 'echo "ssh-ed25519 AAAA... kopia-hostname" >> /config/.ssh/authorized_keys'
    ```

   Keys now persist across restarts via the mounted `config/` directory.
   Each Kopia host should generate a dedicated keypair (not a regular SSH key):

    ```sh
    ssh-keygen -t ed25519 -C "kopia-<hostname>" -f ~/.kopia/sftp_id
    # Add the contents of ~/.kopia/sftp_id.pub using the docker exec command above
    ```

   Side benefit: SSH host keys also persist, so Kopia won't see
   "REMOTE HOST IDENTIFICATION CHANGED" warnings after container restarts.

7. Verify connectivity from the Kopia host:

    ```sh
    ssh -p ${SSTORE_PORT} -i ~/.kopia/sftp_id ${SSTORE_USER}@<SSTORE_LISTEN_ADDR> ls /storage
    ```

## Kopia SFTP backend

When connecting Kopia to this storage:

```sh
kopia repository create sftp \
  --host=<host> --port=<SSTORE_PORT> \
  --username=<SSTORE_USER> --keyfile=~/.kopia/sftp_id \
  --path=/storage --known-hosts-file=/dev/null
```

## Security notes

- `SSTORE_LISTEN_ADDR` controls which interface the port is bound to. `127.0.0.1` (loopback) is the
  default, but VMs on the same host **cannot** reach it — set to the host-VM bridge IP when needed.
  Never use `0.0.0.0` without a firewall.
- `PASSWORD_ACCESS=false` and `SUDO_ACCESS=false` are hardcoded; the container user has no shell or
  sudo rights.
- The private key (`~/.kopia/sftp_id`) never leaves the Kopia host. The container only holds public
  keys in `/config/.ssh/authorized_keys`.
- Each Kopia host should generate its own dedicated keypair. Regular SSH keys should not be reused.
- Public keys are added via `docker exec` on the host — no injection via environment variables,
  keeping the compose file free of any sensitive data.

## References

- [linuxserver/openssh-server](https://docs.linuxserver.io/images/docker-openssh-server/)
- [Kopia SFTP repository](https://kopia.io/docs/repositories/#sftp)
- [Kopia stack](../kopia/)
