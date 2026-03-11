# [0026] Make search flexible with partial and case-insensitive matching

## Summary

The current course search is too strict — users must type exact terms and match casing to get results. Search should support partial matches (e.g. "rail" matching "Rails") and be case-insensitive so users can find courses without worrying about capitalisation. This reduces friction and makes the directory more discoverable.

## Context

- **Phase:** None
- **Depends on:** #0016
- **Blocks:** None

## What needs to happen

1. Search queries match partial words (prefix matching at minimum, so "progr" finds "programming")
2. Search is fully case-insensitive — "RAILS", "rails", and "Rails" all return the same results
3. The existing tsvector/GIN index approach is preserved or enhanced rather than replaced
4. Search behaviour remains consistent when combined with tag filtering and pagination

## Acceptance criteria

### Functionality
- [x] Searching "rail" returns courses with "Rails" in the title or description
- [x] Searching "PYTHON" returns the same results as searching "python"
- [x] Partial matches work for both title and description fields
- [x] Existing exact-match searches continue to work correctly
- [x] Search still combines cleanly with tag filtering and pagination

### Security
- [x] Search input remains sanitised against SQL injection (no raw string interpolation in queries)
- [x] Only approved courses appear in search results regardless of query

### Performance
- [x] Partial and case-insensitive search uses indexes effectively (no full table scans)
- [x] Search response time remains acceptable with the courses dataset under pagination

### Testing
- [x] Tests verify partial word matching returns expected results
- [x] Tests verify case-insensitive matching works for uppercase, lowercase, and mixed-case queries
- [x] Tests verify partial search does not return non-approved courses
