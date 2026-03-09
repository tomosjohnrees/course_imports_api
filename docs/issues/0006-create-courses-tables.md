# [0006] Create courses and validation_attempts tables

## Summary

Create the database migrations for the `courses` and `validation_attempts` tables. These are the core data structures for course submission and validation — courses store metadata extracted from GitHub repos, and validation attempts provide an audit log of every validation run.

## Context

- **Phase:** Milestone 3 — Course Submission & Validation
- **Depends on:** #0001
- **Blocks:** #0007, #0008, #0009, #0010, #0011

## What needs to happen

1. A migration that creates the `courses` table with all columns per the architecture doc, including the PostgreSQL array column for tags
2. A migration that creates the `validation_attempts` table
3. Appropriate indexes: unique composite index on `[github_owner, github_repo]`, GIN index on `tags`, index on `status`, foreign keys to `users` and `courses`

## Acceptance criteria

### Functionality
- [ ] `courses` table exists with all specified columns and correct types/nullability/defaults
- [ ] `validation_attempts` table exists with all specified columns and foreign key to `courses`
- [ ] `courses.status` defaults to `'pending'` and is non-nullable
- [ ] `courses.load_count` defaults to `0`
- [ ] `courses.tags` is a PostgreSQL string array with a default of `{}`
- [ ] Both migrations run cleanly up and down

### Security
- [ ] Foreign key constraints are in place (`courses.user_id` → `users`, `validation_attempts.course_id` → `courses`)

### Performance
- [ ] Unique composite index exists on `[github_owner, github_repo]`
- [ ] GIN index exists on `tags` for efficient array queries
- [ ] Index exists on `status` for filtering approved courses
- [ ] Index exists on `courses.user_id` (via `t.references`)

### Testing
- [ ] Migrations can be verified by running `rails db:migrate` and inspecting the schema
