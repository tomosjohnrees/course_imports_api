# [0012] Rack-attack rate limiting for course submissions

## Summary

Configure `rack-attack` with rate limiting rules to prevent abuse of the course submission endpoint. This includes per-user submission throttling, per-IP general request limits, and an auto-ban for IPs with repeated failed submissions.

## Context

- **Phase:** Milestone 3 — Course Submission & Validation
- **Depends on:** #0011
- **Blocks:** None

## What needs to happen

1. A throttle rule limiting course submissions to 5 per user per hour
2. A general throttle limiting all requests to 20 per minute per IP
3. A blocklist rule that auto-bans IPs with more than 10 failed submission attempts in an hour (24-hour ban)
4. Clear response messages for rate-limited requests

## Acceptance criteria

### Functionality
- [x] Submitting more than 5 courses in an hour from the same user returns a 429 response
- [x] Making more than 20 requests per minute from the same IP returns a 429 response
- [x] An IP that triggers more than 10 POST requests to `/courses` in an hour is blocked for 24 hours
- [x] Rate limit responses include a clear message explaining the limit

### Security
- [x] Rate limiting is active in all environments (or at minimum, production and staging)
- [x] The blocklist prevents sustained abuse of the submission endpoint
- [x] Rate limiting cannot be bypassed by unauthenticated requests (IP-based limits still apply)

### Performance
- [x] Rate limit checks use in-memory or cache-backed storage and do not add significant latency to requests
- [x] Rack-attack is configured early in the middleware stack

### Testing
- [x] Tests verify the per-user submission throttle triggers at the correct threshold
- [x] Tests verify the per-IP general throttle triggers at the correct threshold
- [x] Tests verify the auto-ban blocklist activates after repeated requests

## Notes

The architecture doc includes example `rack-attack` configuration that can be used as a starting point. Consider using `Rails.cache` (Solid Cache) as the rack-attack cache store.
