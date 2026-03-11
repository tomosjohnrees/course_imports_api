# [0037] Add course favouriting

## Summary

Users should be able to favourite (star) a course from the course listing or detail page, and view all their favourited courses in a dedicated "My Favourites" section. This gives learners a lightweight way to bookmark courses they're interested in and return to them later.

## Context

- **Phase:** None
- **Depends on:** None
- **Blocks:** None

## What needs to happen

1. A `course_favourites` join table linking users to courses they have favourited
2. A toggle mechanism on course cards and the course detail page to favourite/unfavourite a course
3. A "My Favourites" page listing all courses a user has favourited
4. Navigation entry point so users can reach their favourites list

## Acceptance criteria

### Functionality
- [x] Authenticated users can favourite a course from the course index or course detail page
- [x] Authenticated users can unfavourite a previously favourited course
- [x] A "My Favourites" page displays all courses the current user has favourited
- [x] The favourite state is visually indicated on course cards and the detail page
- [x] Unauthenticated users do not see the favourite toggle

### Security
- [x] Only authenticated users can create or delete favourites, and only their own
- [x] Users cannot view or modify another user's favourites list

### Performance
- [x] The favourites join table has a composite unique index on (user_id, course_id)
- [x] The "My Favourites" page is paginated if the user has many favourites

### Testing
- [x] Model validations and associations have unit tests covering creation, uniqueness, and deletion
- [x] Controller tests verify authentication requirements and correct scoping to current user
