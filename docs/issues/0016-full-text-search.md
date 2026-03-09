# [0016] Full-text search with PostgreSQL tsvector

## Summary

Add full-text search to the course index using PostgreSQL's built-in `tsvector` and `tsquery`. Users can search courses by title and description via a search input on the index page. This avoids the need for an external search service like Elasticsearch.

## Context

- **Phase:** Milestone 4 — Browse & Search
- **Depends on:** #0015
- **Blocks:** #0019

## What needs to happen

1. A migration adding a generated `tsvector` column on `courses` and a GIN index on it
2. A search scope on the `Course` model that accepts a query string and returns ranked results
3. A search input on the index page that submits via `?q=` query parameter
4. The search scope combines cleanly with other scopes (status, tag filter, pagination)

## Acceptance criteria

### Functionality
- [ ] Searching by title returns matching approved courses
- [ ] Searching by description returns matching approved courses
- [ ] Search results are ranked by relevance
- [ ] An empty search query returns all approved courses (same as unfiltered index)
- [ ] The search input preserves the current query value after submission
- [ ] A "no results" message appears when the search returns nothing

### Security
- [ ] Search input is sanitised to prevent SQL injection (use `plainto_tsquery` or `websearch_to_tsquery`, not raw string interpolation)
- [ ] Only approved courses appear in search results

### Performance
- [ ] The `tsvector` column is a generated column updated automatically by PostgreSQL (no manual trigger maintenance)
- [ ] A GIN index on the `tsvector` column ensures search queries are fast
- [ ] Search combines with pagination — results are not loaded all at once

### Testing
- [ ] Tests verify search by title returns correct results
- [ ] Tests verify search by description returns correct results
- [ ] Tests verify search does not return non-approved courses
- [ ] Tests verify empty query returns all approved courses
- [ ] Tests verify search combines correctly with tag filtering
