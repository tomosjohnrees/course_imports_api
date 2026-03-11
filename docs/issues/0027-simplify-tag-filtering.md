# [0027] Simplify tag filtering to inline links only

## Summary

The standalone tag filter UI (tag cloud/sidebar) will become overwhelming as the number of courses and unique tags grows. Replace it with inline tag links on each course card so users can still filter by tag by clicking a tag on a specific course, but without a dedicated filter control cluttering the page.

## Context

- **Phase:** None
- **Depends on:** #0017
- **Blocks:** None

## What needs to happen

1. The tag cloud / tag filter sidebar is removed from the courses index page
2. Tags displayed on individual course cards remain clickable and link to the filtered index view (`?tag=beginner`)
3. The active tag filter indicator and clear-filter affordance still work when viewing filtered results
4. Combined search + tag filter via URL params continues to work as before

## Acceptance criteria

### Functionality
- [x] No standalone tag filter UI (cloud, sidebar, or dropdown) appears on the courses index
- [x] Each tag on a course card links to the courses index filtered by that tag
- [x] When viewing a tag-filtered index, the active tag is visually indicated
- [x] A clear-filter control is available to return to the unfiltered index
- [x] Existing URL-based tag filtering (`?tag=value`) still works correctly
- [x] Combined search and tag filter (`?q=python&tag=beginner`) still works correctly

### Security
- [x] Tag parameter sanitisation and validation remain unchanged

### Performance
- [x] Removing the tag cloud eliminates the aggregation query on every index page load

### Testing
- [x] Tests verify the tag cloud / filter sidebar is no longer rendered
- [x] Tests verify course card tags link to the filtered index
- [x] Tests verify filtered results display correctly when accessed via tag link
