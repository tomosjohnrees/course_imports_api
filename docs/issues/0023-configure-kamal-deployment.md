# [0023] Configure Kamal deployment pipeline

## Summary

Set up Kamal 2 deployment configuration so the Rails app can be built as a Docker image, pushed to a container registry, and deployed to the Hetzner VPS. This includes configuring PostgreSQL as a Kamal accessory and setting up all required secrets.

## Context

- **Phase:** Milestone 1 — Project Setup & Deployment Pipeline
- **Depends on:** #0022
- **Blocks:** #0024

## What needs to happen

1. `config/deploy.yml` configured with the service name, server IP, registry credentials, domain, and SSL settings
2. PostgreSQL configured as a Kamal accessory, bound to localhost only
3. `SOLID_QUEUE_IN_PUMA` configured for single-server job processing
4. A container registry (Docker Hub or GHCR) set up to receive built images
5. `.kamal/secrets` created with all required environment variables

## Acceptance criteria

### Functionality
- [x] `config/deploy.yml` defines the web service with the correct server IP and domain
- [x] PostgreSQL is defined as a Kamal accessory with persistent volume storage
- [x] `SOLID_QUEUE_IN_PUMA: true` is set so background jobs run within the Puma process
- [x] A container registry is configured and the app can authenticate to push images
- [x] `.kamal/secrets` contains `SECRET_KEY_BASE`, `DATABASE_URL`, and registry credentials
- [x] `kamal config` runs without errors

### Security
- [x] `.kamal/secrets` is listed in `.gitignore` and not committed to the repository
- [x] PostgreSQL accessory is bound to localhost only — not exposed to the public network
- [x] Registry credentials use a scoped access token, not a primary account password
- [x] `SECRET_KEY_BASE` is a cryptographically random value of sufficient length

### Performance
- [x] The Dockerfile uses multi-stage builds to keep the production image small
- [x] Thruster is configured in front of Puma for HTTP/2, compression, and asset caching

### Testing
- [x] `kamal config` validates the deployment configuration without errors
- [x] The Docker image builds successfully locally with `docker build`

## Notes

Thruster is included by default in Rails 8 Docker setups and handles HTTP/2, gzip compression, and X-Sendfile for assets.
