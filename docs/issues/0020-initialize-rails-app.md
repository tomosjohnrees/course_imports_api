# [0020] Initialize Rails 8 application with PostgreSQL and Solid Trifecta

## Summary

Create a new Rails 8 application configured with PostgreSQL as the primary database and the Solid Trifecta (Solid Queue, Solid Cache, Solid Cable) for background jobs, caching, and WebSockets. This is the foundation every subsequent milestone builds on.

## Context

- **Phase:** Milestone 1 — Project Setup & Deployment Pipeline
- **Depends on:** None
- **Blocks:** #0021, #0022

## What needs to happen

1. A Rails 8 application generated with PostgreSQL as the database adapter
2. Solid Queue, Solid Cache, and Solid Cable confirmed as configured and functional
3. Unnecessary boilerplate removed (unused mailer configs, default scaffold stylesheets, etc.)
4. The application boots cleanly in development with `bin/dev` or `bin/rails server`

## Acceptance criteria

### Functionality
- [x] `rails new` creates the application with `--database=postgresql`
- [x] `bin/rails db:prepare` runs without errors and creates the development database
- [x] Solid Queue is configured as the Active Job backend
- [x] Solid Cache is configured as the cache store
- [x] Solid Cable is configured as the Action Cable adapter
- [x] The app starts and responds on `localhost:3000`

### Security
- [x] Default Rails security headers are present (X-Frame-Options, X-Content-Type-Options, etc.)
- [x] `config/credentials.yml.enc` is used for secrets — no plaintext secrets in config files

### Performance
- [x] The app boots in development without unnecessary services or dependencies
- [x] Database configuration uses connection pooling with sensible defaults

### Testing
- [x] Manual verification that the app boots and the `/up` health check returns 200

## Notes

Rails 8 includes the Solid Trifecta by default, so this is mostly confirming the defaults are correct and cleaning up boilerplate.
