# [0022] Provision Hetzner VPS and configure networking

## Summary

Provision a Hetzner CAX21 ARM64 VPS, configure SSH access, set up a cloud firewall, and point the production domain's DNS to the server. This creates the infrastructure target for Kamal deployments.

## Context

- **Phase:** Milestone 1 — Project Setup & Deployment Pipeline
- **Depends on:** #0020
- **Blocks:** #0023

## What needs to happen

1. A Hetzner CAX21 VPS (ARM64, 4 vCPU, 8GB RAM) provisioned and accessible via SSH
2. A cloud firewall configured to allow only ports 22 (SSH), 80 (HTTP), and 443 (HTTPS)
3. The production domain's DNS A record pointing to the server's IP address

## Acceptance criteria

### Functionality
- [x] The VPS is running and accessible via `ssh root@188.245.66.164`
- [x] The domain (courseimports.com) resolves via Cloudflare proxy to the server
- [x] The server is running an ARM64 architecture (CAX21 is ARM64)

### Security
- [x] SSH key authentication is configured — password authentication is disabled
- [x] The Hetzner cloud firewall allows only ports 22, 80, and 443 inbound
- [x] All other ports are blocked, including PostgreSQL's default port 5432

### Performance
- [x] The server specification matches or exceeds CAX21 (4 vCPU, 8GB RAM)
- [x] DNS propagation is complete and the domain resolves consistently

### Testing
- [x] Manual SSH connection to the server succeeds
- [x] Port scan from an external machine confirms only 22, 80, 443 are open

## Notes

This is infrastructure work done outside the codebase (Hetzner console, DNS provider). The deliverable is a server ready for Kamal to deploy to.
