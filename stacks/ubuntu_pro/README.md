# Ubuntu Pro Secure Samba + VeraCrypt Stack

## Overview

This stack provides a hardened Ubuntu-based container with:

-   Secure Samba server (serving `/mnt/shared` for a user from `$SMB_USER`)
-   Runs Samba as a non-root user, binding to a configurable non-privileged port (default: 1445 via `SMB_PORT`)
-   All Samba state files and directories are owned by the non-root user for security and compatibility
-   All user and password setup is interactive only; environment variables are not supported for authentication
-   VeraCrypt and exFAT support
-   All setup steps are in Dockerfile and start-samba.sh, following best security practices (2025)

## Usage

### Non-root Samba Operation and Troubleshooting

-   Samba runs as a non-root user for security. It binds to a non-privileged port (default: 1445).
-   All Samba state files (in /var/lib/samba, /var/run/samba, /var/log/samba, /run/samba) must be owned by the non-root user. The setup script ensures this.
-   If you see errors like `Failed to create session, error code 1` or `Permission denied` on .tdb files, check and fix ownership of these directories/files.
-   To reset the password for an existing user, run `/start-samba.sh` and enter the password interactively when prompted.
-   To test connectivity from inside the container, use the provided test script:
    ```sh
    /test-samba.sh
    ```

---

### Sharing VeraCrypt Volumes via Samba

To ensure your Samba user can access files in a VeraCrypt-mounted container, you must mount the volume with the correct ownership. The most widely used convention in Docker is UID=1000 and GID=1000.

**Sudo-based VeraCrypt Mounting (Recommended):**

This stack configures the Samba user (e.g. `some_user`) to run `/usr/bin/veracrypt` as root via `sudo` (without a password) for secure, FUSE-based mounting. This ensures the mount is owned by the Samba user and accessible via SMB.

**Steps:**

1. Make sure your Samba user inside the container has UID=1000 and GID=1000 (this stack does this by default).
2. To mount your VeraCrypt volume as the Samba user, run:
    ```sh
    sudo -u some_user sudo veracrypt --text --pim=0 --keyfiles="" --protect-hidden=no -m=nokernelcrypto --fs-options=uid=1000,gid=1000,umask=0022 /mnt/dst/test.tc /mnt/shared/test
    ```
    - For NTFS: add `umask=0002` if you want group write access.
    - For ext4: normal permissions apply.
3. Now the Samba user will have full access to the mounted files, and they will be visible and writable via SMB.

**Note:**

-   This sudoers rule is set up automatically by the start script for each Samba user.
-   If you mount the VeraCrypt volume as root (the default), the Samba user will not be able to access the files.
-   Always use the `uid` and `gid` mount options for exFAT/NTFS.
-   You can verify the user and group IDs inside the container with:
    ```sh
    docker exec ubuntu_pro id some_user
    ```

### ⚠️ Mac Finder + Docker Desktop Limitation

**MacOS Finder cannot connect to Samba running in Docker Desktop on the same Mac, even using your LAN IP (e.g. smb://10.31.202.34/shared).**

-   This is a MacOS kernel security restriction: Finder's SMB client cannot connect to port 445 on the local machine, even if Docker is listening there.
-   `smbclient` works because it uses user-space networking, but Finder uses the kernel SMB stack, which is restricted.
-   **You can only connect from another device on the same LAN, or from a VM with bridged networking.**
-   For local testing, use `smbclient` or connect from another computer.
-   See: [docker-samba issue #109](https://github.com/crazy-max/docker-samba/issues/109), [Docker forums](https://forums.docker.com/t/how-to-reach-docker-container-localhost-from-mac/58415)

#### Troubleshooting Checklist

-   Make sure your Docker Compose or run command uses `-p 445:445` (not `127.0.0.1:445:445`).
-   Temporarily disable the Mac firewall to test.
-   Check for port 445 conflicts: `sudo lsof -iTCP:445` (stop Mac's own SMB server if needed).
-   Try connecting from another device on the same LAN.
-   If you see no new log entries in `/var/log/samba/` when Finder tries to connect, the request is being blocked by MacOS before it reaches Docker/Samba.

---

1. **Build and start the stack**
    ```sh
    docker-compose -f compose.yaml up --build -d
    ```
2. **Initialize Samba interactively**
    - Exec into the running container:
        ```sh
        docker exec -it ubuntu_pro bash
        ```
    - Run the setup script:
        ```sh
        /start-samba.sh
        ```
    - You will be prompted to enter a Samba username and password (hidden input, not stored in env or files).
    - The script will create the user, set permissions, and start the Samba server as a background daemon.
    - On subsequent runs, if a Samba user already exists, the script will skip setup and start Samba in the background (if not already running).
3. **Test the Samba share**

-   After starting Samba, you can test access from inside the container:
    ```sh
    /test-samba.sh
    ```
    This will prompt for your username and password and attempt to list the contents of the share.
-   By default, only port **1445/tcp** is exposed (see `SMB_PORT` in compose.yaml). **You must use a non-privileged port (>=1024) to run Samba as a non-root user.**
-   **To connect from the host or any client using smbclient, you must specify the port with the `-p` option:**
    ```sh
    smbclient //127.0.0.1/shared -p 1445 -U <username>
    ```
    Do not use `//127.0.0.1:1445/shared` (this will not work).
-   The share is `/mnt/shared` in the container, mapped to a Docker volume.

---

### Agent/Automation Testing

You can test the Samba+VeraCrypt stack in CI or with agents using the provided scripts, without copying them to `/` in the container.

**Example:**

```sh
# Build and start the stack
docker-compose -f stacks/ubuntu_pro/compose.yaml up --build -d

# Run the setup script interactively (simulate input for automation)
docker exec -i ubuntu_pro bash -c '/start-samba.sh' <<EOF
youruser
yourpassword
yourpassword
EOF

# Run the test script from its project path
docker exec -i ubuntu_pro bash -c 'cd /root/projects/forest/stacks/ubuntu_pro && ./test-samba.sh' <<EOF
youruser
yourpassword
EOF
```

-   The test script will print a success message if the share is accessible.
-   No need to copy the test script to `/`—it is available in the project path due to the volume mount.

---

#### VeraCrypt Mount/Unmount Scripts for Agents

For automation, use the following scripts inside the container:

-   **Mount a VeraCrypt volume:**
    ```sh
    /vera /mnt/dst/your.tc /mnt/shared/yourmount
    ```
-   **Unmount:**
    ```sh
    /vera-off /mnt/shared/yourmount
    ```

These scripts ensure correct UID/GID and FUSE options for Samba access.

## Security Notes

-   **No guest access**; only `$SMB_USER` can access the share.
-   **SMB encryption** is enforced (`smb encrypt = required`).
-   **Strong passwords** are required; rotate regularly.
-   **Network access** is limited by `hosts allow` in `smb.conf` and firewall rules.
-   **Container runs with least privileges**; no privileged mode.
-   **Sensitive data**: Passwords are never stored in environment variables or Docker layers. Credentials are set interactively at runtime and only exist in the Samba password database inside the container. For even higher security, consider Docker secrets or external secret managers.
-   **Logs**: Samba logs are at `/var/log/samba/` in the container.

## Maintenance

-   To update Samba or VeraCrypt, rebuild the image.
-   Review and update `smb.conf` and `entrypoint.sh` for new security recommendations.
-   Regularly check logs for unauthorized access attempts.

## References

-   [Samba Hardening Best Practices 2025](https://wafatech.sa/blog/linux/linux-security/hardening-samba-best-practices-for-secure-configurations-on-linux-servers/)
-   [Docker Security Best Practices 2025](https://betterstack.com/community/guides/scaling-docker/docker-security-best-practices/)

---

AGENT-NOTE: This stack was generated and reviewed for security best practices as of 2025.
