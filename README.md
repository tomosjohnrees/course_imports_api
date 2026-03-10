# Course Imports API

A community course registry built with Rails 8.1. Users authenticate with GitHub OAuth, submit links to public course repositories, and the app validates and indexes them for discoverability. It's a directory, not a platform — all course content stays in GitHub.

## Tech Stack

- **Ruby 4.0.1 / Rails 8.1** with PostgreSQL
- **Solid Trifecta** (Solid Queue, Solid Cache, Solid Cable) — no Redis
- **Propshaft** + **Tailwind CSS** + **import maps** — no Node.js
- **Hotwire** (Turbo + Stimulus)
- **Kamal 2** deploying to Hetzner VPS via Docker
- **Thruster** for HTTP/2 and compression in front of Puma

## Getting Started

Prerequisites: Ruby 4.0.1, PostgreSQL, GitHub OAuth app credentials

```bash
bin/setup    # Install deps, prepare DB
bin/dev      # Start dev server (Rails + Tailwind watcher)
```

The app needs `GITHUB_CLIENT_ID` and `GITHUB_CLIENT_SECRET` configured in Rails credentials for OAuth to work.

## Commands

| Command | Description |
|---|---|
| `bin/dev` | Start dev server (foreman: Rails + Tailwind watcher) |
| `bin/rails server` | Rails server only (no Tailwind watch) |
| `bin/rails db:prepare` | Create and migrate database |
| `bin/rails db:migrate` | Run pending migrations |
| `bin/rails db:rollback` | Rollback last migration |
| `bin/rubocop` | Lint (rubocop-rails-omakase style) |
| `bin/rubocop -a` | Lint with auto-fix |
| `bin/brakeman` | Security static analysis |
| `bin/bundler-audit` | Check gems for known vulnerabilities |

## Architecture

### Course Status Flow

```
pending -> validating -> approved
                      -> failed -> pending (resubmit)
approved -> removed (admin/user action)
```

### Key Components

| Component | Purpose |
|---|---|
| GitHub OAuth (`omniauth-github`) | Only auth mechanism — no passwords |
| Validation service | Validates course repos via GitHub API |
| Validation job | Async validation via Solid Queue |
| GitHub client | Faraday-based, 5s timeout, user's OAuth token |
| Rate limiting (`rack-attack`) | Per-user submission and per-IP request limits |
| JSON API (`api/v1/courses`) | Read-only endpoints for desktop app consumption |

### Database

PostgreSQL with four databases in production: primary, cache (Solid Cache), queue (Solid Queue), cable (Solid Cable).

## Issue Tracking

Issues live in `docs/issues/` as numbered markdown files. See `docs/issues/README.md` for the index and `docs/issues/completed.md` for done items.
