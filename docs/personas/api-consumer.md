# API Consumer

**Who:** A developer integrating with the registry's JSON API to build tools, aggregators, or alternative clients.
**Tech level:** Developer -- expects well-structured endpoints, predictable responses, and clear error codes.
**Patience:** Medium -- will read docs and experiment, but gives up if the API behaves inconsistently.

## What they care about
- Stable, predictable JSON responses they can parse without guessing
- Pagination, filtering, and search working as documented
- Rate limits being transparent so they can build around them

## How they approach the app
- Hits API endpoints directly, never uses the web UI
- Tests edge cases: empty results, bad parameters, rate limit boundaries
- Reads response headers and status codes more carefully than response bodies

## What would frustrate them
- Inconsistent response shapes between endpoints or between success and error cases
- Rate limiting with no indication of limits or retry-after headers
- Undocumented breaking changes to the API contract
