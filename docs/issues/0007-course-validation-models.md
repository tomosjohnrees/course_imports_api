# [0007] Course and ValidationAttempt models

## Summary

Build the `Course` and `ValidationAttempt` models with status constants, scopes, associations, and validations. The `Course` model is the central domain object representing a registered course, and `ValidationAttempt` provides an audit trail of validation runs.

## Context

- **Phase:** Milestone 3 — Course Submission & Validation
- **Depends on:** #0006
- **Blocks:** #0009, #0010, #0011

## What needs to happen

1. A `Course` model with status constants (`pending`, `validating`, `approved`, `failed`, `removed`), scopes for each status, and a scope for approved/public courses
2. Associations: `Course` belongs to `User`, has many `ValidationAttempt`s
3. A `ValidationAttempt` model with association back to `Course`
4. Validations on required fields and URL format

## Acceptance criteria

### Functionality
- [x] `Course` has status constants and scopes for `pending`, `validating`, `approved`, `failed`, `removed`
- [x] `Course` belongs to `User` and has many `ValidationAttempt`s
- [x] `Course` validates presence of required fields (`github_repo_url`, `github_owner`, `github_repo`, `title`)
- [x] `Course` validates format of `github_repo_url` against a strict pattern
- [x] `ValidationAttempt` belongs to `Course` and records `result`, `error_message`, `api_calls_made`, `duration_ms`
- [x] A scope exists to fetch only approved, publicly visible courses

### Security
- [x] Courses are always scoped to a user via the `belongs_to :user` association
- [x] URL validation prevents submission of non-GitHub URLs

### Performance
- [x] Status scopes use the indexed `status` column
- [x] Association queries use foreign key indexes

### Testing
- [ ] Model tests cover all validations (presence, format, uniqueness)
- [ ] Model tests cover status scopes
- [ ] Model tests verify associations work correctly
- [ ] Model tests cover edge cases for URL format validation
