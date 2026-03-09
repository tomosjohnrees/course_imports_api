# [0001] Create users table and schema

## Summary

Create the database migration for the `users` table that stores GitHub OAuth user records. This is the foundational schema for authentication — every other auth-related feature depends on this table existing.

## Context

- **Phase:** Milestone 2 — GitHub Authentication
- **Depends on:** None
- **Blocks:** #0002, #0003, #0004, #0005

## What needs to happen

1. A migration that creates the `users` table with all columns defined in the architecture doc (`github_id`, `github_username`, `github_token`, `display_name`, `avatar_url`, `banned`, timestamps)
2. A unique index on `github_id` to enforce one user per GitHub account
3. Active Record Encryption configured in credentials for encrypting `github_token`

## Acceptance criteria

### Functionality
- [ ] `users` table exists with all specified columns and correct types/nullability
- [ ] `github_id` has a unique index
- [ ] `banned` column defaults to `false` and is non-nullable
- [ ] Migration runs cleanly up and down (`rails db:migrate` and `rails db:rollback`)

### Security
- [ ] Active Record Encryption keys are configured in `credentials.yml` (not committed in plaintext)
- [ ] `github_token` column can store encrypted values (string type with sufficient length)

### Performance
- [ ] Unique index on `github_id` ensures fast lookups during OAuth callback

### Testing
- [ ] Migration can be verified by running `rails db:migrate` and inspecting the schema
