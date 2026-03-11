# [0035] Track course loads via Open in App clicks

## Summary

Course loads are not currently tracked, so there is no visibility into which courses are actually being used. Tracking "Open in App" button clicks will provide usage data while respecting user privacy by deduplicating counts per user.

## Context

- **Phase:** None
- **Depends on:** None
- **Blocks:** None

## What needs to happen

1. A mechanism to record when a user clicks "Open in App" on a course, storing enough to deduplicate per user
2. A load count visible on each course (or available via the API) so popularity is measurable
3. Deduplication logic that prevents the same user — whether logged in or anonymous — from inflating the count with repeated clicks

## Acceptance criteria

### Functionality
- [x] Clicking "Open in App" increments the course's load count
- [x] A logged-in user clicking the same course's "Open in App" multiple times counts as one load
- [x] An anonymous visitor clicking the same course's "Open in App" multiple times counts as one load (e.g. session-based or fingerprint-based deduplication)
- [x] The load count is visible on the course detail page or accessible via the API

### Security
- [x] No personally identifiable information is stored in the tracking data beyond what is necessary for deduplication
- [x] The tracking endpoint cannot be abused to inflate counts (rate-limited or otherwise protected)

### Performance
- [x] Recording a load does not add noticeable latency to the "Open in App" action
- [x] Querying load counts does not introduce N+1 queries on course listing pages

### Testing
- [x] Unit tests cover deduplication logic for both logged-in and anonymous users
- [x] Controller or integration tests verify the tracking endpoint records loads correctly and rejects duplicates
