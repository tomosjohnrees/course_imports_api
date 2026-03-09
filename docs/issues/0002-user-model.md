# [0002] User model with encryption and scopes

## Summary

Build the `User` model with Active Record Encryption for the GitHub token, a `find_or_create_from_omniauth` class method for the OAuth callback, and a `banned` scope. This model is the core identity object for the application.

## Context

- **Phase:** Milestone 2 — GitHub Authentication
- **Depends on:** #0001
- **Blocks:** #0003, #0004, #0005

## What needs to happen

1. A `User` model with `encrypts :github_token` declaration
2. A `find_or_create_from_omniauth(auth_hash)` class method that creates or updates a user from an OmniAuth auth hash
3. A `banned` scope and a convenience method for checking banned status

## Acceptance criteria

### Functionality
- [ ] `User` model exists with appropriate validations (presence of `github_id`, `github_username`)
- [ ] `find_or_create_from_omniauth` creates a new user when none exists for the given `github_id`
- [ ] `find_or_create_from_omniauth` updates existing user attributes (username, avatar, token) on subsequent logins
- [ ] `banned` scope returns only banned users
- [ ] `banned?` method works correctly

### Security
- [ ] `github_token` is encrypted at rest via Active Record Encryption
- [ ] `github_token` is not included in default serialisation or `inspect` output

### Performance
- [ ] `find_or_create_from_omniauth` uses the indexed `github_id` column for lookups

### Testing
- [ ] Model tests cover `find_or_create_from_omniauth` for both new and returning users
- [ ] Model tests verify encryption is active on `github_token`
- [ ] Model tests cover the `banned` scope and `banned?` method
- [ ] Model tests cover validation errors for missing required fields
