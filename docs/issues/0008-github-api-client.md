# [0008] GitHub API client

## Summary

Build a standalone GitHub API client using Faraday that fetches repository metadata, file contents, and directory listings. This client is used by the validation service to verify that submitted repos contain valid course content. It handles authentication, timeouts, and typed error responses.

## Context

- **Phase:** Milestone 3 — Course Submission & Validation
- **Depends on:** None
- **Blocks:** #0009

## What needs to happen

1. A `GithubClient` class (in `lib/` or `app/lib/`) with a Faraday connection configured with a 5-second timeout and JSON response parsing
2. Methods: `fetch_repo_metadata(owner, repo)`, `fetch_file(owner, repo, path)`, `fetch_directory(owner, repo, path)`
3. Optional auth token in the initialiser — uses the token if provided, falls back to unauthenticated
4. Typed exceptions for 404, 403 (rate limit), and network errors

## Acceptance criteria

### Functionality
- [x] `fetch_repo_metadata` returns parsed repo data from the GitHub API
- [x] `fetch_file` returns decoded file contents (handles base64 decoding from the GitHub Contents API)
- [x] `fetch_directory` returns a list of entries in a directory
- [x] All methods raise typed exceptions for 404 (not found), 403 (rate limited), and network timeout errors
- [x] The client accepts an optional OAuth token and includes it as a Bearer token in requests
- [x] The client works without a token for unauthenticated requests

### Security
- [x] OAuth tokens are passed only in the Authorization header, never logged or included in error messages
- [x] The client does not follow redirects to arbitrary hosts

### Performance
- [x] HTTP timeout is set to 5 seconds per request to prevent hung connections
- [x] Faraday connection is reused across calls within the same client instance

### Testing
- [x] Unit tests cover all three methods with stubbed HTTP responses
- [x] Tests cover error handling for 404, 403, and timeout scenarios
- [x] Tests verify token is included in requests when provided
- [x] Tests verify base64 decoding of file contents
