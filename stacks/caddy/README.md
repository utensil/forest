# Caddy Reverse Proxy Stack

This stack provides a Caddy HTTPS reverse proxy for homelab services, using internal domains and subdomains for routing.

## Usage

1. Set the `PODS_HOME` environment variable to your pod home directory (e.g., `/path/to/pods`).

2. Add entries for all stacks to your client machine's hosts file. You can automate this with:

    ```sh
    just prep-homelab [IP]
    ```
    This will scan all stacks and add lines like:
    ```
    127.0.0.1 dockge.homelab.internal
    ```
    (Replace `[IP]` with your server's IP if not running locally; defaults to 127.0.0.1.)

3. Build and start the Caddy stack:

    ```sh
    export PODS_HOME=/path/to/pods
    docker-compose -f stacks/caddy/compose.yml build
    docker-compose -f stacks/caddy/compose.yml up -d
    ```

    Whenever you change the Caddyfile, re-run the build command above.
4. Ensure the dockge stack is running and accessible as `dockge:5001` from the Caddy container (use Docker networking).

5. Visit https://dockge.homelab.internal in your browser (accept the internal CA if prompted).

## Trusting and Untrusting the Caddy Root CA

To enable trusted HTTPS for all `.homelab.local` domains, you must trust the Caddy root CA on your system. This is fully automated:

- **Trust the CA:**
  ```sh
  just trust-ca
  ```
  This adds the Caddy root CA to your system trust store (macOS or Linux). You may need to enter your password for system changes.

- **Untrust the CA:**
  ```sh
  just untrust-ca
  ```
  This safely removes the Caddy root CA from your system trust store (using `rip` for safe file removal on Linux). The script prints the CA subject and fingerprint for manual removal if needed.

**Troubleshooting:**
- If your browser still trusts the CA after running `untrust-ca`, check for duplicate CA entries in your user keychain (macOS Login), browser-specific CA store (e.g., Firefox), or manual imports. Remove all instances to fully untrust.
- After trusting or untrusting, fully quit and restart your browser to clear any cached trust.

## Configuration

- The Caddyfile is version-controlled in this directory and copied into the image at build time (see Dockerfile).
- Caddy data and config are persisted in `${PODS_HOME}/caddy/data` and `${PODS_HOME}/caddy/config`.
- To add more stacks, edit the Caddyfile in this directory and rebuild the image with `docker-compose build`.
- No need to mount the Caddyfile from outside the repo.

## Example Caddyfile

```
dockge.homelab.internal {
    reverse_proxy dockge:5001
    tls internal
}
```
