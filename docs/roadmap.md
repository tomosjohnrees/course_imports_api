# Roadmap

## Overview

A solo project with no fixed deadline. Each milestone ends in a deployable, working state — nothing is left half-finished at the end of a milestone. Milestones are sized to be completable in a focused weekend or a few evenings.

---

## Milestone 1 — Project Setup & Deployment Pipeline

**Goal:** A blank Rails 8 app is deployed to Hetzner and reachable at a real domain. No features yet — but the entire deployment pipeline is working so every subsequent milestone ships to production from day one.

### Rails App
- [ ] `rails new course-registry --database=postgresql` with Rails 8
- [ ] Configure PostgreSQL as primary database
- [ ] Confirm Solid Queue, Solid Cache, Solid Cable are all configured (Rails 8 defaults)
- [ ] Remove any unnecessary boilerplate
- [ ] Set up `rack-attack` gem and add to middleware stack (empty rules for now)
- [ ] Add `omniauth-github` and `faraday` to Gemfile

### Kamal & Hetzner
- [ ] Provision Hetzner CAX21 VPS (ARM64, 4 vCPU, 8GB RAM)
- [ ] Add SSH key to Hetzner server
- [ ] Configure Hetzner cloud firewall (allow 22, 80, 443 only)
- [ ] Point domain DNS A record to Hetzner server IP
- [ ] Configure `config/deploy.yml` — service name, server IP, registry credentials, domain, SSL
- [ ] Add PostgreSQL as a Kamal accessory, bound to localhost only
- [ ] Configure `SOLID_QUEUE_IN_PUMA: true` for single-server job processing
- [ ] Set up Docker Hub (or GHCR) as image registry
- [ ] Create `.kamal/secrets` with all required env vars
- [ ] Run `kamal setup` — installs Docker, starts PostgreSQL accessory
- [ ] Run `kamal deploy` — app live at domain with TLS

### Health Check
- [ ] Confirm `/up` health check endpoint responds 200
- [ ] Confirm HTTPS is working with valid Let's Encrypt cert
- [ ] Confirm PostgreSQL accessory is running and accessible from app container

**Milestone complete when:** The app is live at the real domain over HTTPS, PostgreSQL is running, and `kamal deploy` works from local machine.

---

## Milestone 2 — GitHub Authentication

**Goal:** Users can sign in with GitHub and sign out. User records are created and their OAuth token is stored encrypted. Nothing else yet.

### Database
- [ ] Create `users` migration — `github_id`, `github_username`, `github_token`, `display_name`, `avatar_url`, `banned`, timestamps
- [ ] Configure Active Record Encryption for `github_token` in `credentials.yml`
- [ ] Add uniqueness index on `github_id`

### OmniAuth
- [ ] Configure `omniauth-github` with client ID and secret from credentials
- [ ] Add OmniAuth callback route
- [ ] Implement `SessionsController#create` — find or create user by `github_id`, store encrypted token, set `session[:user_id]`
- [ ] Implement `SessionsController#destroy` — clear session
- [ ] Add CSRF protection for OmniAuth routes (`omniauth-rails_csrf_protection` gem)

### User Model
- [ ] `User` model with `find_or_create_from_omniauth` class method
- [ ] `encrypts :github_token` declaration
- [ ] `banned` scope and check

### Application Controller
- [ ] `current_user` helper method
- [ ] `authenticate_user!` before action
- [ ] `user_signed_in?` helper

### UI
- [ ] Minimal home page with "Sign in with GitHub" button when signed out
- [ ] Show GitHub username and avatar + "Sign out" link when signed in
- [ ] Redirect back to intended page after sign in

### Deployment
- [ ] Add `GITHUB_CLIENT_ID` and `GITHUB_CLIENT_SECRET` to `.kamal/secrets`
- [ ] Deploy and verify GitHub OAuth flow works in production

**Milestone complete when:** A real GitHub account can sign in, a User record is created with an encrypted token, and sign out works.

---

## Milestone 3 — Course Submission & Validation

**Goal:** A signed-in user can submit a GitHub repo URL. The URL is validated asynchronously using Solid Queue and the result is shown on the course status page in real time via Turbo Streams.

### Database
- [ ] Create `courses` migration — all fields per architecture doc
- [ ] Create `validation_attempts` migration
- [ ] Add GIN index on `tags` array column
- [ ] Add unique index on `[github_owner, github_repo]`

### Models
- [ ] `Course` model with status constants and scopes (`pending`, `validating`, `approved`, `failed`, `removed`)
- [ ] `Course` belongs_to `User`, has_many `ValidationAttempt`
- [ ] `ValidationAttempt` model

### GitHub Client (`lib/github_client.rb`)
- [ ] Faraday connection with 5-second timeout and JSON response parsing
- [ ] `fetch_repo_metadata(owner, repo)` — GET `/repos/{owner}/{repo}`
- [ ] `fetch_file(owner, repo, path)` — GET `/repos/{owner}/{repo}/contents/{path}`, decode base64
- [ ] `fetch_directory(owner, repo, path)` — GET `/repos/{owner}/{repo}/contents/{path}`
- [ ] Accept optional auth token in initialiser — use user token if present, fall back to unauthenticated
- [ ] Handle 404, 403 (rate limit), and network errors with typed exceptions

### Validation Service (`app/services/course_validation_service.rb`)
- [ ] Step 1: Fetch repo metadata, check public, check `size <= MAX_REPO_SIZE_KB`
- [ ] Step 2: Fetch and parse `course.json`, validate required fields and length limits
- [ ] Step 3: Fetch `topics/` directory, check count and that folders match `topicOrder`
- [ ] Step 4: Fetch first topic's `content.json`, validate block array structure
- [ ] Return `{ success: true, metadata: {...} }` or `{ success: false, error: "..." }`
- [ ] Log API call count and duration for `ValidationAttempt`

### Validation Job (`app/jobs/course_validation_job.rb`)
- [ ] Set course `status: validating`
- [ ] Call `CourseValidationService`
- [ ] Update course with result — `approved` + metadata, or `failed` + error message
- [ ] Record `ValidationAttempt`
- [ ] Broadcast status update via Turbo Stream

### Controller & Routes
- [ ] `CoursesController#new` — submission form (authenticated)
- [ ] `CoursesController#create` — validate URL format, check for duplicate, create course, enqueue job
- [ ] `CoursesController#show` — course detail and status page
- [ ] `CoursesController#destroy` — user can remove their own course

### Rate Limiting
- [ ] Add `rack-attack` rule: max 5 submissions per user per hour
- [ ] Add `rack-attack` rule: max 20 requests per minute per IP
- [ ] Add `rack-attack` blocklist for repeated failed submissions

### UI
- [ ] Course submission form with URL input and explanatory copy
- [ ] Course status page showing current status — pending, validating, approved, failed
- [ ] Turbo Stream target on status page that updates when validation job broadcasts result
- [ ] Inline error display on submission form for URL format errors and duplicates
- [ ] User's own courses list on their profile/dashboard

### Deployment
- [ ] Deploy and verify end-to-end: submit a real course repo, watch it validate, see it approved

**Milestone complete when:** A valid course repo can be submitted, validates asynchronously, and appears as approved. An invalid repo shows a useful error message. The status updates in real time without a page refresh.

---

## Milestone 4 — Browse & Search

**Goal:** Approved courses are publicly browseable and searchable. The course index is the main public-facing page of the site.

### Course Index
- [ ] `CoursesController#index` — paginated list of approved courses, newest first
- [ ] Display: title, description excerpt, author, tags, topic count, load count
- [ ] Pagination (Pagy gem — lightweight, no dependencies)

### Search
- [ ] Full-text search on `title` and `description` using PostgreSQL `tsvector` — add generated column and GIN index
- [ ] Filter by tag — clicking a tag filters the index to that tag
- [ ] Search input on the index page with `?q=` param
- [ ] Combine search + tag filter in a single clean query scope on `Course`
- [ ] Empty state with helpful message when no results found

### Course Detail Page
- [ ] Public course detail page — title, full description, author, tags, topic count, GitHub repo link, load count
- [ ] "Open in app" button — deep links into the desktop app with the repo URL (custom URL scheme, defined later)
- [ ] "View on GitHub" link

### Tags
- [ ] Tag cloud or tag list on the index page sidebar showing all tags in use
- [ ] Each tag links to filtered index

### UI Polish for Public Pages
- [ ] Clean, simple design consistent with the desktop app's aesthetic (calm, minimal)
- [ ] Responsive layout — readable on mobile even though the desktop app is the primary target
- [ ] Correct `<title>` and meta description tags on all public pages

**Milestone complete when:** The public index is live, search and tag filtering work, and individual course pages are clean and informative.

---

## Milestone 5 — JSON API for the Desktop App

**Goal:** The desktop app can browse, search, and load courses via a JSON API. Load counts are tracked.

### API Controllers
- [ ] `Api::V1::CoursesController#index` — same search/filter params as web, returns JSON
- [ ] `Api::V1::CoursesController#show` — full course metadata as JSON
- [ ] `Api::V1::CoursesController#load` — POST, increments `load_count`, unauthenticated

### API Response Shape
- [ ] Define consistent JSON response envelope: `{ data: [...], meta: { total, page, per_page } }`
- [ ] Course serialiser — returns all fields needed by the desktop app
- [ ] Versioned under `/api/v1/` so future breaking changes don't affect existing desktop app versions

### Rate Limiting
- [ ] Add `rack-attack` rule: API endpoints max 60 requests/minute per IP

### Testing
- [ ] Request specs for all three API endpoints covering happy path and error cases
- [ ] Test search, tag filter, pagination

**Milestone complete when:** The desktop app can call the API and get back a list of courses it can load. Load counts increment correctly.

---

## Milestone 6 — Polish, Edge Cases & Hardening

**Goal:** The app handles abuse and edge cases gracefully, and is ready for real public use.

### Robustness
- [ ] Handle GitHub API rate limit errors gracefully — show user a clear message, don't leave course stuck in `validating`
- [ ] Handle network timeouts in validation job — fail cleanly, record error, let user resubmit
- [ ] Handle duplicate submission race condition — database unique constraint + rescue in controller
- [ ] Handle user deleting their GitHub account — graceful session expiry
- [ ] Ensure banned users cannot submit or have their courses appear in search
- [ ] Admin action: remove a course (sets `status: removed`, hidden from all public views)
- [ ] Admin action: ban a user

### Security Audit
- [ ] Review all controller actions — confirm every write action is scoped to `current_user`
- [ ] Confirm `github_token` never appears in logs, responses, or error messages
- [ ] Confirm PostgreSQL port is not publicly accessible (verify from outside the server)
- [ ] Confirm all secrets are in `.kamal/secrets` and not committed to git
- [ ] Review `rack-attack` rules — confirm rate limits are working in production

### Operational
- [ ] Set up PostgreSQL backups — `pg_dump` to an S3-compatible store (Hetzner Object Storage) via a Kamal accessory or cron job
- [ ] Configure Rails log level and structured logging for production
- [ ] Silence health check requests from logs (`config.silence_healthcheck_path = '/up'`)
- [ ] Set up basic uptime monitoring (UptimeRobot free tier is sufficient)
- [ ] Add a `CHANGELOG.md` and tag v1.0.0 in git

### Copy & UX
- [ ] Review all error messages — plain language throughout
- [ ] Add a simple "About" or FAQ page explaining what the registry is and how to submit a course
- [ ] Add course count to the home page ("X courses from Y authors")

**Milestone complete when:** The app handles all known failure modes cleanly, backups are running, monitoring is in place, and it is ready to share publicly.

---

## Backlog (Post-v1)

- **Re-validation** — button for authors to trigger re-validation after updating their repo
- **Course screenshots / previews** — optional screenshot URL in `course.json`, displayed on the registry
- **Verified badge** — deeper validation pass that checks more than just the first topic
- **Author profiles** — public page per GitHub user showing all their courses
- **Featured courses** — hand-curated list on the home page
- **Submission webhooks** — GitHub webhook to auto-trigger re-validation when a repo is pushed
- **OpenGraph tags** — rich link previews when sharing a course URL
- **Analytics dashboard** — simple admin view of submissions, load counts, and popular tags over time
- **Course collections** — curated lists of related courses (e.g. "Learn to code from scratch")

---

## Related Documents

- `registry_architecture.md` — full technical architecture this roadmap is based on
- `product_overview.md` — course format the validator checks against
- `app_architecture.md` — desktop app that consumes this registry's JSON API
