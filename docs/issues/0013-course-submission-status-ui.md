# [0013] Course submission and status UI with Turbo Streams

## Summary

Build the user-facing views for course submission: the submission form, the course status page with real-time updates via Turbo Streams, inline error display, and a user dashboard showing their submitted courses.

## Context

- **Phase:** Milestone 3 — Course Submission & Validation
- **Depends on:** #0010, #0011
- **Blocks:** #0014

## What needs to happen

1. A course submission form with a URL input field and explanatory copy about what makes a valid course repo
2. A course status page that shows the current status (pending, validating, approved, failed) and updates in real time when the validation job broadcasts a result
3. Inline error display on the submission form for URL format errors and duplicate submissions
4. A user dashboard listing all courses submitted by the current user

## Acceptance criteria

### Functionality
- [x] Submission form has a URL input field with clear instructions
- [x] Form validation errors (bad URL format, duplicate repo) are displayed inline without a full page reload
- [x] Course status page shows the current status with appropriate visual treatment for each state
- [x] When validation completes, the status page updates in real time via Turbo Stream (no manual refresh needed)
- [x] Failed courses display the validation error message
- [x] Approved courses display the extracted metadata (title, description, tags, topic count)
- [x] User dashboard lists all of the current user's courses with their statuses
- [x] User can remove their own course from the dashboard

### Security
- [x] The submission form includes a CSRF token
- [x] The user dashboard only shows courses belonging to the current user

### Performance
- [x] Turbo Stream connection is established only on the status page, not on every page load
- [x] The user dashboard paginates if the user has many courses

### Testing
- [ ] System or integration tests cover the submission flow (submit URL → see pending → see result)
- [ ] Tests verify Turbo Stream updates render correctly on status change
- [ ] Tests verify inline error display for invalid URLs and duplicates
