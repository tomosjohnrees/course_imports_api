# [0014] Deploy and verify course submission flow in production

## Summary

Deploy the complete course submission and validation feature to production and verify the end-to-end flow works with a real GitHub repository. This is the integration checkpoint for Milestone 3.

## Context

- **Phase:** Milestone 3 — Course Submission & Validation
- **Depends on:** #0012, #0013
- **Blocks:** #0015

## What needs to happen

1. Deploy all Milestone 3 code to production via `kamal deploy`
2. Submit a real course repository and verify it validates and is approved
3. Submit an invalid repository and verify it fails with a useful error message
4. Verify real-time status updates work in the browser

## Acceptance criteria

### Functionality
- [ ] A valid course repo can be submitted, validates asynchronously, and appears as approved
- [ ] An invalid repo (e.g. missing course.json) shows a specific, useful error message
- [ ] The course status page updates in real time when validation completes
- [ ] The user dashboard shows the submitted courses
- [ ] Course removal works correctly

### Security
- [ ] Rate limiting is active in production — verify by checking rack-attack logs or response headers
- [ ] Validation uses the user's GitHub token, not a shared token

### Performance
- [ ] Validation completes within a few seconds for a typical course repo
- [ ] Solid Queue is processing jobs correctly (check with `kamal console` if needed)

### Testing
- [ ] Manual smoke test of the full submission flow in production
- [ ] Manual test of submitting an invalid repo and verifying the error message
- [ ] Manual test of real-time status updates
