# [0018] Public course detail page

## Summary

Build the public-facing course detail page that shows full information about an approved course: title, description, author, tags, topic count, GitHub link, load count, and an "Open in app" button for the desktop app.

## Context

- **Phase:** Milestone 4 — Browse & Search
- **Depends on:** #0015
- **Blocks:** #0019

## What needs to happen

1. A public `CoursesController#show` view for approved courses with full metadata
2. A "View on GitHub" link pointing to the course's repository
3. An "Open in app" button that deep-links into the desktop app using a custom URL scheme
4. Course tags link back to the filtered index

## Acceptance criteria

### Functionality
- [x] The detail page displays: title, full description, author name, tags, topic count, GitHub repo link, and load count
- [x] "View on GitHub" link opens the course's GitHub repository
- [x] "Open in app" button generates a deep link URL for the desktop app
- [x] Tags on the detail page link to the filtered course index
- [x] Non-approved courses return a 404 (not accessible via direct URL)

### Security
- [x] Only approved courses are viewable on the public detail page
- [x] No internal data (validation errors, user tokens, internal IDs beyond the course ID) is exposed
- [x] External links use `rel="noopener noreferrer"`

### Performance
- [x] The detail page requires a single database query (no N+1s)
- [x] The page is cacheable for public CDN caching (appropriate cache headers)

### Testing
- [ ] Controller tests verify the detail page renders for approved courses
- [ ] Controller tests verify non-approved courses return 404
- [ ] Tests verify all expected metadata fields are present in the response
