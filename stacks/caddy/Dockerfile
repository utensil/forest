# Use official Caddy image as base
FROM caddy:alpine

# Copy generated Caddyfile into the image
COPY Caddyfile.generated /etc/caddy/Caddyfile

# AGENT-NOTE: This Dockerfile ensures the generated Caddyfile is always present in the image.
