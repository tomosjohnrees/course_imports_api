# [0010] Course validation job with Turbo Stream broadcast

## Summary

Build the `CourseValidationJob` that runs asynchronously via Solid Queue. The job coordinates the validation lifecycle: sets the course status to `validating`, calls the validation service, updates the course with the result, records a `ValidationAttempt`, and broadcasts the status change to the browser via Turbo Stream.

## Context

- **Phase:** Milestone 3 — Course Submission & Validation
- **Depends on:** #0007, #0009
- **Blocks:** #0011, #0013

## What needs to happen

1. A Solid Queue job that accepts a course ID and runs the validation service
2. Status transitions: `pending` → `validating` → `approved` or `failed`
3. A `ValidationAttempt` record created on every run with the result, error message, API call count, and duration
4. A Turbo Stream broadcast after validation completes so the status page updates in real time

## Acceptance criteria

### Functionality
- [ ] Job sets course status to `validating` before calling the service
- [ ] On success, course status is set to `approved` and metadata fields are populated from the validation result
- [ ] On failure, course status is set to `failed` and `validation_error` is set to the error message
- [ ] A `ValidationAttempt` record is created with `result`, `error_message`, `api_calls_made`, and `duration_ms`
- [ ] A Turbo Stream broadcast is sent after validation completes, targeting the course status page
- [ ] If the validation service raises an unexpected error, the course is set to `failed` with a generic error message (not a stack trace)

### Security
- [ ] The job uses the submitting user's OAuth token for GitHub API calls (not a shared app token)
- [ ] Error messages broadcast to the browser do not include internal details or stack traces

### Performance
- [ ] The job has a hard timeout (30 seconds) to prevent hung jobs from blocking the queue
- [ ] If a course is already in `validating` status, a duplicate job for the same course is not enqueued

### Testing
- [ ] Job tests cover the success path — course ends up `approved` with correct metadata
- [ ] Job tests cover the failure path — course ends up `failed` with an error message
- [ ] Job tests verify a `ValidationAttempt` is created in both success and failure cases
- [ ] Job tests verify the Turbo Stream broadcast is sent
