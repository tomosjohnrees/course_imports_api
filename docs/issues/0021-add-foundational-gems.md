# [0021] Add foundational gems to Gemfile

## Summary

Add the gems required by future milestones to the Gemfile: `rack-attack` for rate limiting, `omniauth-github` for GitHub OAuth, and `faraday` for HTTP requests to the GitHub API. Configure `rack-attack` in the middleware stack with empty rules as a placeholder.

## Context

- **Phase:** Milestone 1 — Project Setup & Deployment Pipeline
- **Depends on:** #0020
- **Blocks:** #0001, #0008

## What needs to happen

1. `rack-attack`, `omniauth-github`, `omniauth-rails_csrf_protection`, and `faraday` added to the Gemfile and installed
2. `Rack::Attack` added to the middleware stack with an empty initializer ready for rules
3. The application still boots and passes linting after the additions

## Acceptance criteria

### Functionality
- [x] `rack-attack` is in the Gemfile and an initializer exists at `config/initializers/rack_attack.rb`
- [x] `Rack::Attack` is included in the middleware stack (verifiable via `bin/rails middleware`)
- [x] `omniauth-github` and `omniauth-rails_csrf_protection` are in the Gemfile
- [x] `faraday` is in the Gemfile
- [x] `bundle install` completes without conflicts

### Security
- [x] `omniauth-rails_csrf_protection` is included alongside `omniauth-github` to prevent CSRF on OAuth routes
- [x] No gem versions are pinned to known-vulnerable releases (verify with `bin/bundler-audit`)

### Performance
- [x] Adding the gems does not noticeably increase boot time
- [x] `rack-attack` initializer with empty rules adds no measurable overhead to request processing

### Testing
- [x] Manual verification that `bin/rails server` still boots cleanly
- [x] `bin/rubocop` passes with no new offences
