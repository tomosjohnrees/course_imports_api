# [0033] Hard-delete courses on removal

## Summary

When a user removes a course, the app currently soft-deletes it by setting the status to "removed". The record stays in the database indefinitely, consuming storage and complicating queries that must exclude removed courses. Courses should be fully deleted from the system so the directory only contains live data.

## Context

- **Phase:** None
- **Depends on:** None
- **Blocks:** None

## What needs to happen

1. The course removal action destroys the record from the database instead of toggling a status flag
2. Associated validation attempts are cleaned up when a course is destroyed
3. The "removed" status value is removed from the course model since it is no longer needed
4. Any queries or scopes that filter out removed courses are simplified now that removed records no longer exist

## Acceptance criteria

### Functionality
- [ ] Removing a course deletes the course record and its associated validation attempts from the database
- [ ] The "removed" status is removed from the status enum
- [ ] After removal, the user is redirected with a confirmation message
- [ ] Course index and search results no longer need to exclude a "removed" status

### Security
- [ ] Only the course owner can delete their own course (existing authorisation is preserved)

### Performance
- [ ] Deletion uses a single transaction with cascading deletes rather than loading associations into memory

### Testing
- [ ] Controller tests verify that destroy actually removes the record from the database
- [ ] Controller tests verify that non-owners cannot delete another user's course
