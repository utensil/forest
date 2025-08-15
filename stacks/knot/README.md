# Knot Docker Compose Setup

This directory contains a Docker Compose configuration for running a [Tangled Knot][tangled-knot] instance using the community-maintained `hqnna/knot` image.

## Usage

1. Set the `PODS_HOME` environment variable to your pod home directory (for example, `/path/to/pods`).

2. Start the service (set PODS_HOME to your pod home path):

```sh
export PODS_HOME=/path/to/pods   # set this to your pod home directory

docker-compose -f stacks/knot/docker-compose.yml up -d
```

Docker Compose will automatically create the necessary directories for bind mounts if they do not exist.

This will:
- Expose SSH on port 5522 (host:5522 → container:22)
- Expose the Knot service on port 5555
- Persist keys, repositories, and app data in your pod home

## Web UI / Frontend

> **Important:** The Knot server itself does not serve a web UI at http://localhost:5555/.
>
> The `frontend` section in the official docker-compose.yml is only a Caddy reverse proxy for HTTPS and domain routing—it does not provide a web interface or static assets.
>
> There is no bundled web UI for Knot. If you visit http://localhost:5555/ you will only see a plain info message.
>
> If you want a web UI, you must deploy the [AppView project][appview-project] separately (see the `appview` directory in the tangled-core repo). See its documentation for setup and integration.

## Reference

- [Knot Docker Guide][knot-docker-guide]
- [Docker Hub: hqnna/knot][docker-hub-knot]

> **Note:** This is a community-maintained image. See the guide for advanced options and troubleshooting.

[tangled-knot]: https://tangled.sh
[knot-docker-guide]: https://tangled.sh/@tangled.sh/knot-docker/raw/main/readme.md
[docker-hub-knot]: https://hub.docker.com/r/hqnna/knot
[appview-project]: https://tangled.sh/@tangled.sh/core/tree/main/appview
