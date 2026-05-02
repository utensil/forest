## Backup

# https://www.fuse-t.org/
#
prep-fuse-t:
    brew tap macos-fuse-t/homebrew-cask
    brew install fuse-t
    brew install fuse-t-sshfs

[linux]
prep-vera:
    #!/usr/bin/env bash
    which veracrypt && echo "VeraCrypt is already installed." && exit 0
    set -e
    VERSION="$(cat /etc/os-release | grep "VERSION_ID"|sed -e 's/[^0-9.]//g')"
    echo $VERSION
    DEB_URL="https://launchpad.net/veracrypt/trunk/1.26.24/+download/veracrypt-1.26.24-Ubuntu-$VERSION-amd64.deb"
    TMP_DEB="/tmp/veracrypt-$VERSION.deb"
    curl -L "$DEB_URL" -o "$TMP_DEB"
    sudo apt install -y "$TMP_DEB"
    rm -f "$TMP_DEB"
    echo "VeraCrypt installed successfully."
    # exfatprogs is the official implementation from Samsung, replacing the older reverse-engineered exfat-utils. It offers better performance and reliability https://linux.how2shout.com/how-to-check-and-enable-exfat-support-in-ubuntu/
    apt install -y exfat-fuse exfatprogs
    which mount.exfat || ln -s /usr/sbin/mount.exfat-fuse /usr/sbin/mount.exfat
    grep exfat /etc/filesystems || echo exfat >> /etc/filesystems
    # create a test tc container using exfat and test it with
    # veracrypt --text -mnokernelcrypto --password=test --non-interactive ~/projects/forest/output/test.tc /mnt/test

# Install VeraCrypt that works with FUSE-T (on Mac)
[macos]
prep-vera:
    which veracrypt || brew install --cask veracrypt-fuse-t

# Install VeraCrypt that works with macFUSE (on Mac)
[macos]
prep-vera-kernel:
    which veracrypt || brew install --cask veracrypt

[macos]
vera VOLUME MNT *PARAMS:
    veracrypt --text {{VOLUME}} {{MNT}} # --non-interactive --password=THE_PASSWORD

[linux]
vera VOLUME MNT *PARAMS:
    mkdir -p {{MNT}}
    veracrypt --text --pim=0 --keyfiles="" --protect-hidden=no -m=nokernelcrypto {{PARAMS}} {{VOLUME}} {{MNT}}

vera-ro VOLUME MNT:
    just vera {{VOLUME}} {{MNT}} --mount-options=ro

vera-off MNT:
    veracrypt --text -d {{MNT}}

try-smb PATH:
    #!/usr/bin/env bash
    # -d
    #--network host
    just clone crazy-max docker-samba
    cd ~/projects/docker-samba/examples/compose/
    mkdir public
    mkdir share
    touch share/something
    rip foo
    ln -s {{PATH}} foo
    mkdir foo-baz
    docker run \
      -it --rm \
      -p 127.0.0.1:445:445 \
      -e SAMBA_LOG_LEVEL=3 \
      -v "./data:/data" \
      -v "./foo:/samba/foo" \
      --name samba ghcr.io/crazy-max/samba
    # test with: smbclient //127.0.0.1/share -U foo
    # Mac finder not working

prep-smb-cli:
    which smbclient || brew install samba

prep-dav:
    #!/usr/bin/env bash
    set -e
    apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y davfs2
    echo "davfs2 installed. Version:"
    davfs2 --version || true

dav URL MNT="/mnt/dav":
    #!/usr/bin/env bash
    # This task is intended to be run inside the container.
    # It will prompt for WebDAV credentials interactively via mount.davfs.
    set -e
    echo "Creating mount point in container..."
    mkdir -p {{MNT}}
    echo "Mounting WebDAV share (you will be prompted for credentials)..."
    mount -t davfs {{URL}} {{MNT}}
    echo "Listing files in mount point:"
    ls -l {{MNT}}

dav-off MNT="/mnt/dav":
    #!/usr/bin/env bash
    # Unmount the WebDAV mount point (default: /mnt/dav)
    set -e
    echo "Unmounting WebDAV share at {{MNT}}..."
    umount {{MNT}}
    echo "Unmounted {{MNT}}."

dav-ro URL MNT="/mnt/dav":
    #!/usr/bin/env bash
    # Mount the WebDAV share read-only. Prompts for credentials interactively.
    set -e
    echo "Creating mount point in container..."
    mkdir -p {{MNT}}
    echo "Mounting WebDAV share read-only (you will be prompted for credentials)..."
    mount -t davfs {{URL}} {{MNT}} -o ro
    echo "Listing files in mount point:"
    ls -l {{MNT}}

prep-rest:
    #!/usr/bin/env bash
    # which restic || brew install restic
    which backrest || (brew tap garethgeorge/homebrew-backrest-tap
    brew install backrest)
    brew services restart backrest
    echo "visit http://127.0.0.1:9898"

mnt-rest REPO:
    #!/usr/bin/env bash
    mkdir -p ~/.mnt/{{REPO}}
    open ~/.mnt/{{REPO}}
    ~/.local/share/backrest/restic mount -r ~/.rest/{{REPO}} ~/.mnt/{{REPO}}

export DREST_HOME := join(home_directory(), ".drest")

prep-drest:
    docker pull garethgeorge/backrest:latest
    mkdir -p {{DREST_HOME}}/.backrest/config
    mkdir -p {{DREST_HOME}}/.backrest/data
    mkdir -p {{DREST_HOME}}/.backrest/cache

drest:
    # echo $DREST_HOME
    echo "Visit http://127.0.0.1:19898"
    docker run --rm -p 19898:9898 -e BACKREST_PORT=9898 -e BACKREST_DATA=/data -e XDG_CACHE_HOME=/cache -v $DREST_HOME/.backrest/config:/.config/backrest -v $DREST_HOME/.backrest/data:/data -v $DREST_HOME/.backrest/cache:/cache garethgeorge/backrest:latest

prep-kopia:
    which kopia || (brew install kopia; brew install --cask kopiaui)

prep-annex:
    which git-annex || brew install git-annex
    # brew services start git-annex
    mkdir -p ~/annex
    (cd ~/annex && git annex webapp)

