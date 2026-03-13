# docker-socket-proxy

Exposes the Colima Docker socket as a TCP endpoint on the isolated Host-VM network,
allowing AI agents (e.g. OpenClaw) running in a VM to call Docker on the host's
Colima runtime — without exposing anything to external networks or Tailscale.

## Network Topology

```
Host Mac  (Host-VM network IP, e.g. 192.168.64.1)
  └─ Colima VM (docker daemon)
       └─ socket: ~/.config/colima/default/docker.sock  (vz type)
            └─ docker-socket-proxy (this stack)
                 └─ listens on <DOCKER_PROXY_BIND>:2375 only

VM Mac  (Host-VM network IP, e.g. 192.168.64.9)
  └─ AI agent (OpenClaw etc.)
       └─ DOCKER_HOST=tcp://<DOCKER_PROXY_BIND>:2375
```

The Host-VM network (e.g. `192.168.64.0/24`) is a private NAT network isolated from:
- The external internet
- Tailscale (only the VM connects to Tailscale, not the host)

## Setup

### 1. Find your values

On the Host Mac:

```bash
# Find Colima socket path
find ~/.config/colima ~/.colima -name "docker.sock" 2>/dev/null | head -1

# Find Host IP on the VM-facing network
/sbin/ifconfig | grep "inet 192.168"
```

### 2. Configure .env

```bash
cp .env.example .env
# Edit .env: set COLIMA_SOCKET and DOCKER_PROXY_BIND
```

### 3. Start the proxy

```bash
# From stacks/docker-socket-proxy/
docker compose up -d

# Or using the just task (from forest root):
just pod-proxy
```

The `just pod-proxy` task auto-detects the socket path — no manual `.env` editing needed.

### 4. Configure the VM

On the VM, set `DOCKER_HOST` to point at the host:

```bash
# In ~/.zshrc or equivalent:
export DOCKER_HOST="tcp://<DOCKER_PROXY_BIND>:2375"

# Test:
docker ps
docker info
```

## Colima Socket Path Note

| Colima VM type | Socket location |
|---|---|
| `--vm-type=vz` (Apple VZ) | `~/.config/colima/default/docker.sock` |
| Default (QEMU) | `~/.colima/default/docker.sock` |

`docker context ls` may report the wrong path. Use `find` to locate the actual socket.

## Security Notes

- Port 2375 is bound **only to the Host-VM network interface** — not reachable from external network or Tailscale
- Socket is mounted **read-only** at the OS level
- Fine-grained API permission control via environment variables in `compose.yaml`
- `BUILD` and `COMMIT` are disabled by default
