# Linkwarden Stack

This stack provides a self-hosted [Linkwarden](https://linkwarden.app) instance using Docker Compose, following best practices from other stacks in this repository.

## Usage

1. **Set the `PODS_HOME` environment variable** to your pod home directory (e.g., `/path/to/pods`).

2. **Copy and configure environment variables:**

   ```sh
   cp .env.in .env
   # Edit .env and set strong secrets for NEXTAUTH_SECRET, POSTGRES_PASSWORD, and MEILI_MASTER_KEY
   ```

3. **Ensure the `homelab` Docker network exists:**

   ```sh
   docker network ls | grep homelab || docker network create homelab
   ```

4. **Start the stack:**

   ```sh
   docker compose -f compose.yaml up -d
   ```

5. **Access Linkwarden:**

   Open [http://localhost:3000](http://localhost:3000) in your browser.

---

**Note:**
- Only the Linkwarden web service joins the external `homelab` Docker network so that Caddy or other services can proxy to it.
- Make sure your Caddy instance is also on the `homelab` network for internal service discovery.

## Files

- `compose.yaml` — Docker Compose file for Linkwarden, Postgres, and Meilisearch
- `.env.in` — Template for required environment variables (copy to `.env` and fill in)

## Environment Variables

- `NEXTAUTH_URL` — Auth callback URL (default: http://localhost:3000/api/v1/auth)
- `NEXTAUTH_SECRET` — Secret for NextAuth (must be strong and unique)
- `POSTGRES_PASSWORD` — Password for Postgres database
- `MEILI_MASTER_KEY` — Secret key for Meilisearch

For advanced configuration, see the [official .env.sample](https://github.com/linkwarden/linkwarden/blob/main/.env.sample) and [Linkwarden documentation](https://docs.linkwarden.app/self-hosting/installation).

## Data Persistence

- Postgres data: `./pgdata/`
- Linkwarden uploads: `./data/`
- Meilisearch data: `./meili_data/`

## References

- [Linkwarden Self-Hosting Guide](https://docs.linkwarden.app/self-hosting/installation)
- [Linkwarden GitHub](https://github.com/linkwarden/linkwarden)

---

*This stack follows the conventions of other stacks in this repository. For questions, see the main project README or ask in the Linkwarden community.*
