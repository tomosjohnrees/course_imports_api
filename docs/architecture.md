# Architecture

## Overview

A Rails 8 web application that acts as a community course registry. Users authenticate with GitHub, submit links to their public course repositories, and the app validates and indexes them for discoverability. The app stores only metadata — all course content stays in GitHub.

The registry is intentionally thin. It is a directory, not a platform. It does not store or serve course files.

---

## What Rails 8 Gives Us For Free

Rails 8 significantly simplifies this stack compared to previous versions. Several things that previously required external services or third-party gems are now built in.

### The Solid Trifecta — Redis is gone

Rails 8 ships three database-backed adapters that together eliminate Redis as a dependency entirely:

**Solid Queue** replaces Sidekiq for background job processing. It uses PostgreSQL's `FOR UPDATE SKIP LOCKED` mechanism for efficient job handling and supports delayed jobs, concurrency control, retries, and recurring jobs. The validation worker runs here — no Redis, no separate Sidekiq process, no separate service to manage on Hetzner. It has been proven at scale, running 20 million jobs per day at HEY.

**Solid Cache** replaces Redis for caching. It stores cache data in the database using disk rather than RAM, which means much larger caches at lower cost. For a registry app at this scale the performance difference from Redis is negligible.

**Solid Cable** replaces Redis for Action Cable WebSocket connections. Useful if we want to push real-time validation status updates to the browser rather than polling.

Together these mean our Hetzner server runs one process (Rails + Puma) with one database (PostgreSQL) — no Redis sidecar, no Sidekiq process, no extra moving parts.

### Built-in authentication generator

Rails 8 ships `rails generate authentication` which scaffolds a complete session-based auth system. However — since we're doing GitHub OAuth only (no passwords), this generator is not directly useful to us. We still need `omniauth-github`. The generator is worth knowing about but we won't use it.

### Kamal 2 — deployment is built in

Kamal 2 is bundled with Rails 8 and is the default deployment tool. It handles:

- Building and pushing a Docker image of the app
- SSHing into the Hetzner server and pulling the image
- Zero-downtime deploys by starting the new container before stopping the old one
- Automatic TLS via Let's Encrypt (handled by `kamal-proxy`, which replaced Traefik in Kamal 2)
- Managing accessory services (PostgreSQL container) alongside the app

No PaaS required. No Heroku, no Fly.io, no Render markup. Just a Hetzner VPS.

### Thruster — HTTP/2 and compression built in

Thruster is a lightweight Go proxy that runs in front of Puma in production. It is installed by default in Rails 8's generated Dockerfile. It provides HTTP/2 support, gzip compression, X-Sendfile support, and basic HTTP caching. No Nginx configuration needed.

### Propshaft — simpler asset pipeline

Rails 8 defaults to Propshaft instead of Sprockets. Simpler, faster, fewer footguns. No change in what we do, but worth knowing the pipeline has changed.

---

## Technology Stack

| Layer | Technology | Notes |
|---|---|---|
| Framework | Ruby on Rails 8 | |
| Database | PostgreSQL | Primary datastore; also backs Solid Queue and Solid Cache |
| Background jobs | Solid Queue | Built into Rails 8 — no Redis or Sidekiq needed |
| Caching | Solid Cache | Built into Rails 8 — no Redis needed |
| WebSockets | Solid Cable | Built into Rails 8 — for real-time validation status |
| Authentication | OmniAuth + `omniauth-github` | GitHub OAuth only — no passwords |
| Rate limiting | `rack-attack` | Per-user and per-IP limits |
| HTTP client | `faraday` | GitHub API calls with timeout config |
| Asset pipeline | Propshaft | Rails 8 default |
| HTTP proxy | Thruster | Rails 8 default, runs in front of Puma |
| Deployment | Kamal 2 | Rails 8 default, deploys to Hetzner via Docker |
| Server | Hetzner VPS | CAX21 recommended (4 vCPU ARM, 8GB RAM, ~€7/month) |

---

## Hetzner Setup

### Recommended server spec

For a registry app at early stage, the **CAX21** (ARM-based, 4 vCPU, 8GB RAM) is more than enough and costs around €7/month. ARM instances on Hetzner are significantly cheaper than x86 for equivalent specs.

If building locally on an x86 Mac or Linux machine, configure Kamal to do a remote build on the server itself to avoid cross-architecture image issues:

```yaml
# config/deploy.yml
builder:
  arch: arm64
  remote: ssh://root@<server-ip>
```

### Firewall rules

Hetzner's cloud firewall should be configured to allow only:

- TCP 22 (SSH) — from your IP only if possible
- TCP 80 (HTTP) — Kamal proxy redirects to HTTPS
- TCP 443 (HTTPS)

Everything else closed. PostgreSQL (port 5432) must not be publicly exposed — it runs in a Docker container on an internal network and is accessed by the Rails container only.

### DNS

Point your domain's A record to the Hetzner server IP. Kamal proxy handles TLS certificate provisioning via Let's Encrypt automatically on first deploy — no manual Certbot setup.

---

## Kamal 2 Configuration

```yaml
# config/deploy.yml
service: course-registry
image: your-dockerhub-username/course-registry

servers:
  web:
    hosts:
      - <hetzner-server-ip>
    labels:
      traefik.http.routers.course-registry.rule: Host(`yourcourseregistry.app`)

proxy:
  ssl: true
  host: yourcourseregistry.app

registry:
  username: your-dockerhub-username
  password:
    - KAMAL_REGISTRY_PASSWORD

env:
  secret:
    - RAILS_MASTER_KEY
    - GITHUB_CLIENT_ID
    - GITHUB_CLIENT_SECRET
    - POSTGRES_PASSWORD
  clear:
    SOLID_QUEUE_IN_PUMA: true   # Run Solid Queue worker inside the Puma process (single server)

builder:
  arch: arm64

accessories:
  postgres:
    image: postgres:16
    host: <hetzner-server-ip>
    port: 127.0.0.1:5432:5432   # Bind to localhost only — not publicly exposed
    env:
      secret:
        - POSTGRES_PASSWORD
      clear:
        POSTGRES_USER: course_registry
        POSTGRES_DB: course_registry_production
    volumes:
      - /var/lib/postgresql/data:/var/lib/postgresql/data

aliases:
  console: app exec --interactive --reuse "bin/rails console"
  shell:   app exec --interactive --reuse "bash"
  logs:    app logs -f
  dbc:     app exec --interactive --reuse "bin/rails dbconsole"
```

`SOLID_QUEUE_IN_PUMA: true` runs the Solid Queue worker inside the Puma web process rather than as a separate process. Fine for a single server — simplifies the setup considerably.

---

## Data Model

### `users`

Created on first GitHub OAuth login. No passwords stored.

```ruby
create_table :users do |t|
  t.string  :github_id,       null: false, index: { unique: true }
  t.string  :github_username, null: false
  t.string  :github_token     # OAuth token — encrypted at rest
  t.string  :display_name
  t.string  :avatar_url
  t.boolean :banned,          default: false, null: false
  t.timestamps
end
```

`github_token` is stored encrypted using Rails 7+ Active Record Encryption (`encrypts :github_token`). It is used for GitHub API calls during validation and is never exposed in responses or logs.

---

### `courses`

One row per registered course. Contains only metadata derived from `course.json` — no content.

```ruby
create_table :courses do |t|
  t.references :user,          null: false, foreign_key: true
  t.string  :github_repo_url,  null: false
  t.string  :github_owner,     null: false
  t.string  :github_repo,      null: false
  t.string  :course_id
  t.string  :title,            null: false
  t.text    :description
  t.string  :version
  t.string  :author_name
  t.string[] :tags,            default: []
  t.integer :topic_count
  t.string  :status,           null: false, default: 'pending'
  t.text    :validation_error
  t.integer :repo_size_kb
  t.datetime :last_validated_at
  t.integer :load_count,       default: 0
  t.timestamps

  t.index [:github_owner, :github_repo], unique: true
  t.index :status
  t.index :tags, using: :gin
end
```

**Status state machine:**

```
pending → validating → approved
                    ↘ failed

approved → removed   (admin action or user deletion)
failed   → pending   (user resubmits after fixing their repo)
```

---

### `validation_attempts`

Audit log of every validation run. Used for debugging and abuse detection.

```ruby
create_table :validation_attempts do |t|
  t.references :course,   null: false, foreign_key: true
  t.string  :result       # passed | failed | rejected
  t.text    :error_message
  t.integer :api_calls_made
  t.integer :duration_ms
  t.timestamps
end
```

---

## Authentication Flow

```
User clicks "Sign in with GitHub"
        │
        ▼
Redirected to GitHub OAuth consent screen
        │
        ▼
GitHub redirects back with auth code
        │
        ▼
OmniAuth exchanges code for access token
        │
        ▼
Rails callback action:
  - Find or create User by github_id
  - Store/refresh github_token (encrypted via Active Record Encryption)
  - Set session[:user_id]
        │
        ▼
User is signed in
```

---

## Course Submission Flow

Submission is always asynchronous. The web request enqueues a job and returns immediately.

```
User submits a GitHub repo URL
        │
        ▼
CourseSubmissionsController#create
  - Must be signed in
  - Rate limit: max 5 submissions per user per hour (rack-attack)
  - Validate URL format
  - Check repo not already registered by another user
  - Create Course record (status: pending)
  - Enqueue CourseValidationJob via Solid Queue
  - Respond 202, redirect to course status page
        │
        ▼  (async, Solid Queue worker inside Puma)
CourseValidationJob#perform
  - Set status: validating
  - Run CourseValidationService
  - Set status: approved or failed
  - Record ValidationAttempt
  - Broadcast status update via Solid Cable (Turbo Stream)
```

The status page uses a Turbo Stream broadcast to update in real time when validation completes — no polling needed.

---

## Validation Service

`CourseValidationService` applies strict limits at every step before fetching anything unnecessary. Maximum ~6 GitHub API calls per validation.

### Step 1 — Repo metadata (1 API call)

```
GET /repos/{owner}/{repo}

Checks:
  - Repo exists
  - Repo is public
  - repo.size <= 5,000 KB (5MB)
  - Not archived or disabled

Rejects most abuse attempts here before any file fetching.
```

### Step 2 — Fetch course.json (1 API call)

```
GET /repos/{owner}/{repo}/contents/course.json

Checks:
  - File exists and size <= 50KB
  - Valid JSON
  - Has required fields: id, title, description, topicOrder
  - title <= 200 chars, description <= 2,000 chars
  - topicOrder is an array with 1–50 entries

Extracts: title, description, id, version, author, tags, topic_count
```

### Step 3 — Topics directory (1 API call)

```
GET /repos/{owner}/{repo}/contents/topics

Checks:
  - Directory exists
  - Entry count <= 50
  - At least one entry matches topicOrder
```

### Step 4 — Spot-check first topic (1–2 API calls)

```
GET /repos/{owner}/{repo}/contents/topics/{first_topic}/content.json

Checks:
  - File exists and size <= 100KB
  - Valid JSON array
  - At least 1 block
  - Each block has a type field
  - No more than 100 blocks
```

### Hard limits

```ruby
MAX_REPO_SIZE_KB     = 5_000
MAX_TOPIC_COUNT      = 50
MAX_TITLE_LENGTH     = 200
MAX_DESCRIPTION_LENGTH = 2_000
MAX_COURSE_JSON_KB   = 50
MAX_CONTENT_JSON_KB  = 100
MAX_BLOCKS_PER_TOPIC = 100
HTTP_TIMEOUT_SECS    = 5
```

---

## Security

### Authentication & Authorisation

- All write actions require an authenticated session
- Users can only modify their own courses — always scope to `current_user.courses`
- Admin actions gated behind an `admin` boolean on `User`
- GitHub tokens encrypted at rest with Active Record Encryption

### Rate Limiting (`rack-attack`)

```ruby
# Max 5 course submissions per user per hour
Rack::Attack.throttle('submissions per user', limit: 5, period: 1.hour) do |req|
  req.session['user_id'] if req.path == '/courses' && req.post?
end

# General request rate limit per IP
Rack::Attack.throttle('requests per IP', limit: 20, period: 1.minute) do |req|
  req.ip
end

# Auto-ban IPs with repeated failed submission attempts
Rack::Attack.blocklist('abusive IPs') do |req|
  Rack::Attack::Allow2Ban.filter(req.ip, maxretry: 10, findtime: 1.hour, bantime: 24.hours) do
    req.path == '/courses' && req.post?
  end
end
```

### GitHub API Abuse Prevention

- Validation always runs in a Solid Queue background job — never in the web request
- Per-request HTTP timeout of 5 seconds via Faraday
- Repo size check (Step 1) happens before any file fetching
- Validation uses the submitting user's OAuth token, consuming their rate limit (5,000/hour) not the app's shared budget
- Solid Queue concurrency capped at a low number for the validation queue

### Job Queue Protection

- Solid Queue runs inside Puma on a single server (`SOLID_QUEUE_IN_PUMA: true`)
- Jobs have a hard timeout — a hung validation job is killed after 30 seconds
- Failed validation jobs are not retried automatically — user must explicitly resubmit
- Unique constraint: if a course is already validating, a second job for the same course ID is dropped

### Input Validation

- Repo URL validated against a strict regex before any processing
- All data saved to the database comes from `course.json`, not user form input, and is length-capped before save
- Tags capped at 10 items, each max 50 chars
- `course_id` validated as alphanumeric + hyphens only

---

## JSON API (for the Desktop App)

```
GET /api/v1/courses
  ?q=python       # full-text search on title, description, tags
  ?tag=beginner   # filter by tag
  ?page=1         # 20 per page

GET /api/v1/courses/:id

POST /api/v1/courses/:id/load
  # Increments load_count — unauthenticated, fire-and-forget
```

Read endpoints are unauthenticated and rate-limited to 60 requests/minute per IP via `rack-attack`.

---

## Project Structure

```
app/
├── controllers/
│   ├── sessions_controller.rb
│   ├── courses_controller.rb
│   └── api/v1/courses_controller.rb
├── models/
│   ├── user.rb
│   ├── course.rb
│   └── validation_attempt.rb
├── jobs/
│   └── course_validation_job.rb
├── services/
│   └── course_validation_service.rb
├── lib/
│   └── github_client.rb
└── views/
    ├── courses/
    │   ├── index.html.erb
    │   ├── show.html.erb
    │   └── new.html.erb
    └── sessions/
        └── new.html.erb

config/
├── deploy.yml          # Kamal 2 configuration
├── queue.yml           # Solid Queue configuration
└── cache.yml           # Solid Cache configuration
```

---

## Environment Variables

```bash
# .kamal/secrets (never committed to git)
RAILS_MASTER_KEY=...
KAMAL_REGISTRY_PASSWORD=...
GITHUB_CLIENT_ID=...
GITHUB_CLIENT_SECRET=...
POSTGRES_PASSWORD=...
```

All secrets are injected by Kamal at deploy time. The `RAILS_MASTER_KEY` is used by Active Record Encryption to encrypt the stored GitHub OAuth tokens.

---

## Deployment Workflow

```bash
# First time setup — installs Docker on server, starts accessories
kamal setup

# Deploy a new version — zero downtime
kamal deploy

# Open a Rails console on the server
kamal console

# Tail production logs
kamal logs

# Rollback to previous version
kamal rollback
```

---

## What the App Does Not Do

- Does not clone or mirror course content
- Does not re-validate courses on a schedule
- Does not authenticate users beyond GitHub OAuth
- Does not charge money or gate any content
- Does not serve course files

---

## Related Documents

- `product_overview.md` — course format specification the validator checks against
- `app_architecture.md` — desktop app that consumes this registry's API
- `roadmap.md` — desktop app delivery plan
