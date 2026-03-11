# [0036] Use GitHub username/repo as course URL path

## Summary

Course URLs currently expose internal database IDs (e.g. `/courses/1`), which is fragile and leaks implementation details. Switching to `/courses/username/repo` makes URLs human-readable, stable, and aligned with the GitHub-centric nature of the app.

## Context

- **Phase:** None
- **Depends on:** None
- **Blocks:** None

## What needs to happen

1. Courses are routable by GitHub owner and repository name instead of numeric ID
2. All existing links, redirects, and references to courses use the new URL scheme
3. Lookups by owner/repo are efficient and enforce uniqueness

## Acceptance criteria

### Functionality
- [ ] Course show page is accessible at `/courses/:username/:repo`
- [ ] All internal links to courses (index, detail, edit, API) use the owner/repo path
- [ ] Numeric ID URLs no longer resolve (or redirect to the canonical owner/repo URL)
- [ ] The owner and repo pair is unique — no two course records share the same combination

### Security
- [ ] Route parameters are validated to prevent path traversal or injection via username/repo values
- [ ] Authorization checks still apply correctly when looking up courses by owner/repo

### Performance
- [ ] Database lookups by owner and repo name use an index and perform comparably to ID-based lookups

### Testing
- [ ] Controller tests verify courses are accessible at the new URL scheme and that old numeric paths are handled
- [ ] Model tests verify uniqueness enforcement on the owner/repo combination
