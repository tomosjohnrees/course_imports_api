# [0011] CoursesController for submission and management

## Summary

Build the `CoursesController` with actions for submitting a new course, viewing course status, and removing a course. This is the main controller for the course submission flow — it validates the URL, checks for duplicates, creates the course record, and enqueues the validation job.

## Context

- **Phase:** Milestone 3 — Course Submission & Validation
- **Depends on:** #0007, #0010
- **Blocks:** #0013

## What needs to happen

1. `new` action — renders the submission form (requires authentication)
2. `create` action — validates URL format, checks for duplicate repos, creates a `Course` record, enqueues `CourseValidationJob`, redirects to the course show page
3. `show` action — displays course details and current validation status
4. `destroy` action — allows a user to remove their own course

## Acceptance criteria

### Functionality
- [x] `new` requires authentication and renders the submission form
- [x] `create` validates the GitHub repo URL format before processing
- [x] `create` checks for an existing course with the same `github_owner` and `github_repo` and rejects duplicates
- [x] `create` parses the owner and repo name from the URL
- [x] `create` creates a `Course` record in `pending` status and enqueues `CourseValidationJob`
- [x] `create` redirects to the course `show` page after successful submission
- [x] `show` displays the course's current status and metadata (or validation error if failed)
- [x] `destroy` removes a course by setting its status to `removed`
- [x] `destroy` only works for courses owned by the current user

### Security
- [x] All actions except `show` require authentication
- [x] `destroy` is scoped to `current_user.courses` — users cannot remove other users' courses
- [x] URL input is validated and sanitised before being stored
- [x] Strong parameters are used — only permitted attributes are accepted

### Performance
- [x] Duplicate check uses the unique composite index on `[github_owner, github_repo]`
- [x] The `create` action responds quickly — validation runs asynchronously in the background job

### Testing
- [ ] Controller tests cover successful course creation and job enqueuing
- [ ] Controller tests cover URL validation errors (invalid format, non-GitHub URL)
- [ ] Controller tests cover duplicate submission rejection
- [ ] Controller tests verify authentication is required for `new`, `create`, and `destroy`
- [ ] Controller tests verify a user cannot destroy another user's course
