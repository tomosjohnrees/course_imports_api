# [0039] Redesign course action button placement

## Summary

The action buttons on the course detail page (View on GitHub, Open in app, Remove Course) lack intentional placement and hierarchy. "Open in app" is the primary action for most users but is buried at the bottom of the detail page and absent from search results entirely, adding unnecessary friction. The buttons need rethinking so the most important actions are prominent and accessible where users need them.

## Context

- **Phase:** None
- **Depends on:** None
- **Blocks:** None

## What needs to happen

1. "Open in app" is promoted to a primary, prominent action on the course detail page — not hidden below all metadata
2. "Open in app" is available on course cards in search results so users can load a course without navigating to the detail page
3. "View on GitHub" is repositioned as a secondary/utility action since it's less commonly needed than opening in-app
4. "Remove Course" remains accessible to course owners but clearly separated from primary actions to prevent accidental clicks
5. Button hierarchy and visual weight reflect actual usage priority: Open in app > View on GitHub > Remove Course

## Acceptance criteria

### Functionality
- [x] "Open in app" appears near the top of the course detail page, above course metadata
- [x] "Open in app" is visible on course cards in search/index results for approved courses
- [x] "View on GitHub" is demoted to a secondary visual style (e.g. text link or ghost button) on both detail and card views
- [x] "Remove Course" remains on the detail page only, visually separated from primary actions
- [x] "Resubmit for Validation" button placement is reviewed and consistent with the new hierarchy
- [x] Button placement works across all course statuses (pending, validating, approved, failed, removed)

### Security
- [x] "Remove Course" remains gated behind ownership check and confirmation dialog

### Performance
- [x] Adding buttons to course cards does not introduce additional database queries (deep link URL is already available on the course model)

### Testing
- [x] View tests verify button presence and placement across course statuses and ownership scenarios
