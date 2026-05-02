## Container and friends

# prep-pod:
#    # brew uninstall orbstack
#    which docker || brew install docker
#    brew install podman-desktop
#    docker context use default

prep-pod:
    which docker || (brew install docker; brew link docker)
    which docker-compose || brew install docker-compose
    which colima || brew install colima
    which kubectl || brew install kubectl
    docker context use colima

# https://github.com/abiosoft/colima?tab=readme-ov-file#customizing-the-vm
# to run x86_64 containers:
# 1. run colima delete which will delete all existing container!
# 2. colima start --vm-type=vz --vz-rosetta --network-address
# 3. docker pull --platform linux/amd64 ubuntu:jammy # with docker login first
# see also:
# `just prep-lima` which prepares a Lima VM with Ubuntu 25.04 x86_64 that is ready to run x86_64 static binaries and containers
# https://github.com/lima-vm/lima/discussions/1573 for realizing the VM is still arm64
# https://github.com/lima-vm/lima/discussions/1043#discussioncomment-3560889 for realizing only statically linked binaries work in VM, dynamically linked ones fail due to missing shared libraries, so they should be run in containers, so just use colima options for this!
#
# to access lan, `--network-address` is needed
# see https://github.com/abiosoft/colima/blob/main/docs/FAQ.md#the-virtual-machines-ip-is-not-reachable
#
pod CMD="start --vm-type=vz --vz-rosetta --network-address --mount-type=virtiofs":
    colima {{CMD}}

# Expose Colima docker socket to lume VM with permission control.
#
# Architecture (two layers):
#   Layer 1 — Permission control: docker-socket-proxy runs inside Colima VM
#             binding to localhost:2375 (POST: 0 = no container creation by agents)
#   Layer 2 — Transport:          SSH tunnel maps Host Mac <HOST_VM_IP>:2375
#             → Colima VM localhost:2375
#
# Security model:
#   - Container CREATION: human-gated (PR review → merge → manual docker compose up)
#   - Container LIFECYCLE: agent-delegated (start/stop/restart/pause/exec)
#   - No auto-start on boot — must run 'just pod-proxy' explicitly to grant access
#   - 'just pod-proxy stop' immediately revokes agent access
#
# VM end: export DOCKER_HOST=tcp://<HOST_VM_IP>:2375
#
pod-proxy CMD="start":
    #!/usr/bin/env bash
    PID_FILE=/tmp/colima-docker-proxy.pid
    PROXY_NAME=colima-docker-socket-proxy
    PROXY_BIND=$(/sbin/ifconfig 2>/dev/null | grep "inet 192.168" | awk '{print $2}' | head -1)

    # Persistent SSH config path — NOT a temp file; deleted only on stop.
    # Using mktemp + immediate rm caused a race: SSH backgrounded before it could read the file.
    SSH_CONF=/tmp/colima-docker-ssh.conf

    _start_proxy() {
        if colima ssh -- docker inspect "$PROXY_NAME" --format '{{"{{"}}{{".State.Running"}}{{"}}"}}' 2>/dev/null | grep -q "true"; then
            echo "  docker-socket-proxy: already running inside Colima"
            return 0
        fi
        # Silently remove stale container if any (expected to not exist on first run)
        colima ssh -- docker rm -f "$PROXY_NAME" >/dev/null 2>&1 || true
        colima ssh -- docker run -d \
            --name "$PROXY_NAME" \
            --restart unless-stopped \
            -v /run/docker.sock:/var/run/docker.sock:ro \
            -p 127.0.0.1:2375:2375 \
            -e POST=0 \
            -e PING=1 -e VERSION=1 -e INFO=1 -e EVENTS=1 \
            -e CONTAINERS=1 -e IMAGES=1 -e NETWORKS=1 -e VOLUMES=1 \
            -e ALLOW_START=1 -e ALLOW_STOP=1 -e ALLOW_RESTARTS=1 -e ALLOW_PAUSE=1 \
            -e EXEC=1 \
            tecnativa/docker-socket-proxy >/dev/null
        echo "  docker-socket-proxy: started inside Colima (POST=0, EXEC=1)"
    }

    SSH_LOG=/tmp/colima-docker-ssh.log

    _start_tunnel() {
        if [ -z "$PROXY_BIND" ]; then
            echo "Error: Could not detect Host-VM network IP."
            exit 1
        fi
        if [ -f "$PID_FILE" ] && kill -0 $(cat "$PID_FILE") 2>/dev/null; then
            echo "  SSH tunnel:          already running (PID: $(cat $PID_FILE))"
            return 0
        fi
        # Write SSH config to a persistent path (not temp) — SSH reads it after backgrounding
        colima ssh-config > "$SSH_CONF"
        # Forward Host Mac <PROXY_BIND>:2375 → Colima VM localhost:2375 (docker-socket-proxy)
        # colima ssh-config sets ControlMaster=auto + ControlPath=... + ControlPersist=yes.
        # With just -o ControlMaster=no, SSH still connects as a slave via the ControlPath socket,
        # and a -N session (no remote command) ends immediately. Must bypass ControlPath entirely.
        ssh -F "$SSH_CONF" colima -N \
            -o ControlMaster=no -o ControlPath=none \
            -L "$PROXY_BIND:2375:localhost:2375" \
            2>"$SSH_LOG" &
        SSH_PID=$!
        echo $SSH_PID > "$PID_FILE"
        sleep 0.5
        if kill -0 $SSH_PID 2>/dev/null; then
            echo "  SSH tunnel:          started (PID: $SSH_PID) → $PROXY_BIND:2375"
        else
            echo "Error: SSH tunnel failed to start. SSH output:"
            cat "$SSH_LOG" >&2
            rm -f "$PID_FILE" "$SSH_CONF" "$SSH_LOG"
            exit 1
        fi
    }

    _stop_tunnel() {
        if [ -f "$PID_FILE" ]; then
            PID=$(cat "$PID_FILE")
            kill "$PID" 2>/dev/null && echo "  SSH tunnel:          stopped" || true
            rm -f "$PID_FILE"
        else
            echo "  SSH tunnel:          not running"
        fi
        rm -f "$SSH_CONF" "$SSH_LOG"
    }

    _stop_proxy() {
        colima ssh -- docker stop "$PROXY_NAME" 2>/dev/null | grep -q . && \
            colima ssh -- docker rm "$PROXY_NAME" 2>/dev/null | grep -q . && \
            echo "  docker-socket-proxy: stopped" || \
            echo "  docker-socket-proxy: not running"
    }

    case "{{CMD}}" in
        start)
            echo "Starting docker proxy..."
            _start_proxy
            _start_tunnel
            echo "✓ Ready — VM: export DOCKER_HOST=tcp://$PROXY_BIND:2375"
            ;;
        stop)
            echo "Stopping docker proxy..."
            _stop_tunnel
            _stop_proxy
            echo "✓ Access revoked"
            ;;
        restart)
            echo "Restarting docker proxy..."
            _stop_tunnel; _stop_proxy
            sleep 0.5
            _start_proxy; _start_tunnel
            echo "✓ Ready — VM: export DOCKER_HOST=tcp://$PROXY_BIND:2375"
            ;;
        status)
            echo -n "SSH tunnel:            "
            if [ -f "$PID_FILE" ] && kill -0 $(cat "$PID_FILE") 2>/dev/null; then
                echo "running (PID: $(cat $PID_FILE)) → $PROXY_BIND:2375"
            else
                echo "not running"
            fi
            echo -n "docker-socket-proxy:   "
            if colima ssh -- docker inspect "$PROXY_NAME" --format '{{"{{"}}{{".State.Running"}}{{"}}"}}' 2>/dev/null | grep -q "true"; then
                echo "running (Colima VM localhost:2375, POST=0)"
            else
                echo "not running"
            fi
            ;;
        *)
            echo "Usage: just pod-proxy [start|stop|restart|status]"
            exit 1
            ;;
    esac

# tested in lima
# distrobox create --name test --init --image quay.io/toolbx-images/alpine-toolbox:latest
# distrobox enter test
# https://github.com/89luca89/distrobox/blob/main/docs/compatibility.md#containers-distros
[linux]
prep-dist:
    which distrobox || sudo apt install -y distrobox
    which docker || sudo apt install podman-docker

k8s:
    colima start --kubernetes

docker-save IMAGE FILE:
    docker save {{IMAGE}} -o {{FILE}}

prep-lima:
    which lima || brew install lima
    # limactl stop default
    # limactl delete default
    limactl create --name=default dotfiles/lima/ubuntu-25.04-x86_64.yaml
    # limactl start default
    # lima

prep-tilt:
    which tilt || brew install tilt-dev/tap/tilt

# tilt up is usually all you need
#
tilt *PARAMS:
    tilt {{PARAMS}}

# https://github.com/louislam/dockge
# https://github.com/abiosoft/colima/issues/265
#
dockge COMMAND="up" NETWORK_MODE="bridge":
    #!/usr/bin/env bash
    set -e
    [[ -n "$PODS_HOME" ]] || (echo "PODS_HOME is missing" && exit 1)
    mkdir -p $PODS_HOME/dockge/data
    # keep track of stacks in this repo
    rip $PODS_HOME/dockge/stacks || true
    ln -s {{justfile_directory()}}/stacks $PODS_HOME/dockge/stacks
    cd stacks/dockge
    # DOCKGE_ENABLE_CONSOLE=true
    # if COMMAND is up
    export NETWORK_MODE={{NETWORK_MODE}}
    if [ "{{COMMAND}}" = "up" ]; then
        docker-compose up -d
        echo Dockge is now running on http://localhost:5001
    elif [ "{{COMMAND}}" = "down" ]; then
        docker-compose down
    fi

# https://github.com/abiosoft/colima/issues/1234
#
prep-ctop:
    which ctop || brew install ctop
    docker context ls

# https://github.com/abiosoft/colima/issues/958#issuecomment-3078908176
# ? - help
# l - log
# e - execute shell
# w - open browser (convention: first port is http)
#
ctop:
    colima status
    DOCKER_HOST=`docker context ls --format json|grep colima|jq -r '.DockerEndpoint'` ctop

prep-lazydocker:
    brew install jesseduffield/lazydocker/lazydocker

# prep-act: prep-term
#     #!/usr/bin/env bash
#     which act || brew install act

# act:
#     ./act.sh

rm-act:
    sudo docker stop act-dev
    sudo docker rm act-dev

mk-act:
    sudo docker run -d --name act-dev -v{{justfile_directory()}}:/root/projects/forest -p 127.0.0.1:1210-1214:1210-1214 ghcr.io/catthehacker/ubuntu:act-latest bash -c 'sleep infinity'

run-act CMD="bash" OPTS="-it":
    sudo docker exec {{OPTS}} -w /root/projects/forest act-dev {{CMD}}

# manually run bt-ubuntu first, or we won't even have just
#
prep-act:
    # for brew and zsh
    just prep-ubuntu
    just prep-act-in-zsh

prep-act-in-zsh:
    #!/usr/bin/env bash
    source ~/.zshrc
    just prep-term
    just prep-rust
    just prep-lvim-in-zsh
    echo 'To start lvim in server mode, run: just lv-remote'
    echo 'Then from outside the container, run: just lv-local'

## VM

prep-aria2:
    which aria || brew install aria2

prep-lume:
    which lume || /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/trycua/cua/main/libs/lume/scripts/install.sh)"

update-lume:
    lume-update

## SSH

reset-ssh-keys:
    rip ~/.ssh/id_*; rip ~/.ssh/*_rsa; rip ~/.ssh/*_dsa; rip ~/.ssh/*_ecdsa; rip ~/.ssh/*_ed25519 || true

# still verifying
#
prep-ssh-keys:
    #!/usr/bin/env bash
    key_path=~/.ssh/id_ed25519
    if [[ ! -f "$key_path" && ! -f "$key_path.pub" ]]; then
        echo "Generating new SSH key pair..."
        ssh-keygen -t ed25519 -a 100 -f "$key_path" -q -N ""
        chmod 600 "$key_path" "$key_path.pub"
        echo "SSH keys generated and permissions set."
    else
        echo "SSH keys already exist at $key_path and $key_path.pub"
        echo "Skipping key generation."
    fi
    cat "$key_path.pub"
    # Read remote user and host
    read "remote_user?Enter remote username: " || return
    read "remote_host?Enter remote hostname or IP: " || return

    # Ask if user wants to proceed with key deployment
    if read -q "?Do you want to deploy the public key now? (y/n) "; then
        echo  # Add a newline after the prompt
        if ssh-copy-id -x -i "$key_path.pub" "$remote_user@$remote_host"; then
            echo "Public key deployed successfully!"
            echo "You can now connect with: ssh $remote_user@$remote_host"
        else
            echo "Failed to deploy key. Please check connection or manually add the key:"
            cat "$key_path.pub"
        fi
    else
        echo "\nPublic key was not deployed. You can manually add this key:"
        cat "$key_path.pub"
    fi

# initial draft, not verified
#
prep-ssh-server:
    #!/usr/bin/env bash

    # Check if running as root
    if [[ $EUID -ne 0 ]]; then
        echo "This script must be run as root"
        exit 1
    fi

    # Prompt for the public key
    echo "Please paste your public SSH key (typically from ~/.ssh/id_rsa.pub):"
    read -r public_key

    # Verify the key looks like a valid SSH public key
    if [[ ! "$public_key" =~ ^ssh-(rsa|dss|ed25519|ecdsa) ]]; then
        echo "Error: This doesn't look like a valid SSH public key"
        exit 1
    fi

    # Create .ssh directory if it doesn't exist
    mkdir -p /root/.ssh

    # Add key to authorized_keys
    echo "$public_key" >> /root/.ssh/authorized_keys

    # Set correct permissions
    chmod 700 /root/.ssh
    chmod 600 /root/.ssh/authorized_keys

    # Configure SSH server (uncomment to enable)
    # echo "Adding key to SSH server configuration..."
    # echo "PermitRootLogin prohibit-password" >> /etc/ssh/sshd_config
    # echo "AuthorizedKeysFile .ssh/authorized_keys" >> /etc/ssh/sshd_config

    # Restart SSH service (uncomment to enable)
    # echo "Restarting SSH service..."
    # if command -v systemctl >/dev/null; then
    #     systemctl restart sshd
    # else
    #     service ssh restart
    # fi

    echo "Public key added to /root/.ssh/authorized_keys"
    echo "You should now be able to SSH as root using this key"



## Remote

prep-chisel:
    #!/usr/bin/env bash
    which chisel || (curl https://i.jpillora.com/chisel! | bash)

# default ports are ordered so it's clear that local nvim -> local 1212 -> mid 1213 -> remote nvim 1214
# authenticated by environment variable AUTH user:pass
#
cs-remote PORT="1213":
    chisel server -v --port {{PORT}}

cs_mid := env("CS_MID", "localhost:1213")

cs-local MID=cs_mid LOCAL="1212" TARGET="1214":
    chisel client -v http://{{MID}} {{LOCAL}}:{{TARGET}}

nv-remote PROJ="forest" PORT="1214":
    just nvim {{PROJ}} --embed --listen localhost:{{PORT}}

nv-local PROJ="forest" PORT="1212":
    just nvim {{PROJ}} --server localhost:{{PORT}} --remote-ui

# an alternative is use local on CentOS and remote on Ubuntu in docker, no chisel needed, just docekr port mapping
#
lv-remote PROJ="forest" HOST="0.0.0.0" PORT="1214":
    #!/usr/bin/env bash
    just lvim {{PROJ}} --embed --listen {{HOST}}:{{PORT}}

lv-local PROJ="forest" HOST="localhost" PORT="1214":
    #!/usr/bin/env bash
    just lvim {{PROJ}} --server {{HOST}}:{{PORT}} --remote-ui

prep-ts:
    # brew install tailscale
    brew install homebrew/cask/tailscale-app

prep-ts-ssh:
    go install github.com/derekg/ts-ssh@main

# --list
# USER@HOST:PORT
#
ts-ssh *PARAMS:
    `go env GOPATH`/bin/ts-ssh {{PARAMS}}

prep-scp:
    which termscp || brew install veeso/termscp/termscp

scp *PARAMS:
    termscp {{PARAMS}}


