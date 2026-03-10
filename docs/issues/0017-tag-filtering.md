# [0017] Tag filtering and tag cloud

## Summary

Add tag-based filtering to the course index so users can browse courses by topic. A tag cloud or tag list on the index page shows all tags in use, and clicking a tag filters the course list. Tag filtering combines with full-text search for precise discovery.

## Context

- **Phase:** Milestone 4 — Browse & Search
- **Depends on:** #0015
- **Blocks:** #0019

## What needs to happen

1. A scope on `Course` that filters by tag using PostgreSQL's array containment operator
2. A combined query scope that supports both search and tag filter together
3. A tag cloud or tag list in the index page sidebar showing all tags currently in use across approved courses
4. Clicking a tag links to the filtered index (`?tag=beginner`)

## Acceptance criteria

### Functionality
- [x] Filtering by tag shows only approved courses that include that tag
- [x] Tag filter combines with full-text search (e.g. `?q=python&tag=beginner`)
- [x] A tag cloud or list displays all unique tags from approved courses
- [x] Each tag in the cloud links to the filtered index view
- [x] The active tag filter is visually indicated on the page
- [x] Clearing the tag filter returns to the unfiltered index

### Security
- [x] Tag parameter is validated and sanitised before use in queries
- [x] Only tags from approved courses are shown in the tag cloud

### Performance
- [x] Tag filtering uses the GIN index on the `tags` array column
- [x] The tag cloud query is efficient (aggregates tags from approved courses without loading all course records)
- [x] Tag filtering combines with pagination

### Testing
- [x] Tests verify filtering by tag returns only matching courses
- [x] Tests verify combined search + tag filter returns correct results
- [x] Tests verify the tag cloud includes only tags from approved courses
- [x] Tests verify an invalid or nonexistent tag returns an empty result set
