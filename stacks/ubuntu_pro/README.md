# Ubuntu Pro Secure Samba + VeraCrypt Stack

## Overview

This stack provides a hardened Ubuntu-based container with:

-   Secure Samba server (serving `/mnt/shared` for a user from `$SMB_USER`)
-   VeraCrypt and exFAT support
-   All setup steps are in Dockerfile and start-samba.sh, following best security practices (2025)

## Usage

### Sharing VeraCrypt Volumes via Samba

To ensure your Samba user can access files in a VeraCrypt-mounted container, you must mount the volume with the correct ownership. The most widely used convention in Docker is UID=1000 and GID=1000.

**Steps:**

1. Make sure your Samba user inside the container has UID=1000 and GID=1000 (this stack does this by default).
2. When mounting your VeraCrypt volume, use:
    ```sh
    veracrypt --text --mount /path/to/container.vc /mnt/shared --filesystem=exfat --fs-options=uid=1000,gid=1000
    ```
    - For NTFS: add `umask=0002` if you want group write access.
    - For ext4: normal permissions apply.
3. Now the Samba user will have full access to the mounted files.

**Note:**

-   If you mount the VeraCrypt volume as root (the default), the Samba user will not be able to access the files.
-   Always use the `uid` and `gid` mount options for exFAT/NTFS.
-   You can verify the user and group IDs inside the container with:
    ```sh
    docker exec ubuntu_pro id utensil
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
3. **Access the Samba share**
    - Only port **445/tcp** is exposed for maximum security (modern SMB clients only).
    - Connect to `//<host>/shared` as the username and password you entered.
    - The share is `/mnt/shared` in the container, mapped to a Docker volume.

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
