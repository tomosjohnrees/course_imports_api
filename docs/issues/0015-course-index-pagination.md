# [0015] Course index page with pagination

## Summary

Build the public course index page — the main landing page of the registry. It displays a paginated list of approved courses, newest first, showing title, description excerpt, author, tags, topic count, and load count.

## Context

- **Phase:** Milestone 4 — Browse & Search
- **Depends on:** #0007
- **Blocks:** #0016, #0017, #0018, #0019

## What needs to happen

1. A `CoursesController#index` action that lists approved courses with pagination
2. Pagination using the Pagy gem (lightweight, no dependencies)
3. Each course card displays: title, truncated description, author name, tags, topic count, and load count

## Acceptance criteria

### Functionality
- [ ] The index page lists only approved courses, newest first
- [ ] Each course entry shows title, description excerpt, author, tags, topic count, and load count
- [ ] Pagination controls appear when there are more courses than the per-page limit
- [ ] The page works when there are zero courses (empty state with a helpful message)
- [ ] Course titles link to the individual course detail page

### Security
- [ ] Only courses with `status: approved` are shown — no pending, failed, or removed courses appear
- [ ] No sensitive data (user tokens, validation errors) is exposed on the index page

### Performance
- [ ] The query uses the `status` index and avoids N+1 queries (eager load associations as needed)
- [ ] Pagination keeps response size bounded (20-25 courses per page)
- [ ] Page loads efficiently even with hundreds of courses

### Testing
- [ ] Controller tests verify only approved courses are returned
- [ ] Controller tests verify pagination works correctly
- [ ] Tests cover the empty state (no approved courses)
