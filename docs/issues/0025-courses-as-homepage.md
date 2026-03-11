# [0025] Make courses page the homepage

## Summary

The courses listing should be the first thing users see when they visit the site. Currently the root route does not point to the courses index, which adds an unnecessary click before users can search and browse. Making courses the homepage reduces friction and puts the app's core value front and centre.

## Context

- **Phase:** None
- **Depends on:** #0011 (courses controller must exist)
- **Blocks:** None

## What needs to happen

1. The root route points to the courses index action
2. Any existing static or splash homepage is removed or repurposed
3. The dedicated "Courses" navigation link is removed since the homepage now serves that purpose
4. The courses page renders a search-friendly layout suitable as a landing page

## Acceptance criteria

### Functionality
- [ ] Visiting `/` renders the courses listing
- [ ] The courses page includes a visible search/filter entry point
- [ ] The separate "Courses" nav link is removed from the navigation
- [ ] Navigation still allows users to reach authentication and submission flows

### Security
- [ ] The homepage is accessible to unauthenticated visitors without exposing private data

### Performance
- [ ] The courses index query is efficient with an index scan and does not degrade as course count grows

### Testing
- [ ] A routing or integration test verifies that the root path resolves to the courses index
