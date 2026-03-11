# [0038] Broadcast full course card on validation complete

## Summary

When a course finishes validation, the Turbo Stream broadcast only replaces the status badge partial. Metadata populated during validation — tags, topic count, author, description — doesn't appear until the user manually refreshes the page. The broadcast should replace the entire course card so all newly-populated fields are visible immediately.

## Context

- **Phase:** None
- **Depends on:** None
- **Blocks:** None

## What needs to happen

1. The broadcast target and partial are updated so the full course representation is replaced, not just the status badge
2. The course show page displays all validated metadata (tags, topic count, description, author) immediately after approval without a page refresh
3. The dashboard course list entry is also updated via broadcast when validation completes

## Acceptance criteria

### Functionality
- [ ] When a course transitions to approved, the broadcast replaces the full course card including tags, topic count, author, description, and status
- [ ] When a course transitions to failed, the broadcast replaces the card showing the updated status and validation error
- [ ] The validating status transition is also broadcast so users see the intermediate state

### Security
- [ ] Broadcast channels remain scoped to the individual course so users cannot subscribe to other courses' updates

### Performance
- [ ] The broadcast partial renders efficiently without additional database queries beyond the course record itself

### Testing
- [ ] Broadcast replacement is tested to confirm the correct partial and target are used for each status transition
