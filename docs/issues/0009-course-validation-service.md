# [0009] Course validation service

## Summary

Build the `CourseValidationService` that validates a submitted GitHub repository against the course format specification. The service runs a multi-step validation (repo metadata, course.json, topics directory, first topic spot-check) and returns a structured result with extracted metadata or a clear error message.

## Context

- **Phase:** Milestone 3 — Course Submission & Validation
- **Depends on:** #0008
- **Blocks:** #0010

## What needs to happen

1. A service that accepts a course record and a GitHub client, then runs the four validation steps defined in the architecture doc
2. Step 1: Fetch repo metadata — check public, check size limit, check not archived
3. Step 2: Fetch and parse `course.json` — validate required fields, length limits, topic order
4. Step 3: Fetch topics directory — check count, verify folders match `topicOrder`
5. Step 4: Spot-check first topic's `content.json` — validate block array structure
6. Returns a structured result: success with extracted metadata, or failure with a human-readable error

## Acceptance criteria

### Functionality
- [ ] Validation runs all four steps in order, stopping at the first failure
- [ ] Step 1 rejects private repos, oversized repos (> 5MB), and archived repos
- [ ] Step 2 rejects missing/invalid `course.json`, missing required fields, and values exceeding length limits
- [ ] Step 3 rejects missing topics directory and mismatches between directory contents and `topicOrder`
- [ ] Step 4 rejects missing or invalid `content.json` in the first topic
- [ ] On success, returns extracted metadata (title, description, tags, topic count, version, author, course_id)
- [ ] On failure, returns a specific, human-readable error message explaining what went wrong
- [ ] Tracks API call count and total duration for logging

### Security
- [ ] The service does not expose raw GitHub API responses to the caller — only validated, extracted fields
- [ ] All string values from `course.json` are length-capped before being returned

### Performance
- [ ] Validation makes at most 6 GitHub API calls (stops early on failure)
- [ ] Hard limits are enforced: `MAX_REPO_SIZE_KB`, `MAX_TOPIC_COUNT`, `MAX_TITLE_LENGTH`, `MAX_DESCRIPTION_LENGTH`, etc.

### Testing
- [ ] Tests cover the happy path — a fully valid repo passes all four steps
- [ ] Tests cover each failure mode individually (private repo, oversized, bad JSON, missing fields, etc.)
- [ ] Tests verify that validation stops at the first failure and does not make unnecessary API calls
- [ ] Tests verify extracted metadata matches the input course.json

## Notes

Hard limits from the architecture doc: `MAX_REPO_SIZE_KB = 5_000`, `MAX_TOPIC_COUNT = 50`, `MAX_TITLE_LENGTH = 200`, `MAX_DESCRIPTION_LENGTH = 2_000`, `MAX_COURSE_JSON_KB = 50`, `MAX_CONTENT_JSON_KB = 100`, `MAX_BLOCKS_PER_TOPIC = 100`.
