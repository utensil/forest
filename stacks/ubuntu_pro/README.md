# Ubuntu Pro Secure Samba + VeraCrypt Stack

## Overview

This stack provides a hardened Ubuntu-based container with:

-   Secure Samba server (serving `/mnt/shared` for a user from `$SMB_USER`)
-   VeraCrypt and exFAT support
-   All setup steps are in Dockerfile and start-samba.sh, following best security practices (2025)

## Usage

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
    - The script will create the user, set permissions, and start the Samba server in the foreground.
    - On subsequent runs, if a Samba user already exists, the script will skip setup and start Samba directly.
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
