# [0034] Add course authoring guide page with downloadable skill

## Summary

Users need a public-facing page that explains how to author a course compatible with Course Imports — covering the folder structure, metadata format, block types, and content best practices. The page should also offer the `/creating-course` Claude Code skill as a downloadable file so authors can generate courses automatically. This lowers the barrier to entry for course creators and drives submissions.

## Context

- **Phase:** None
- **Depends on:** None
- **Blocks:** None

## What needs to happen

1. A new publicly accessible page (e.g. `/authoring-guide`) that renders the course authoring specification in a readable, navigable format
2. The page content covers folder structure, `course.json` schema, block types, validation checklist, and writing guidance (sourced from `docs/creating-course/course_authoring_guide.md`)
3. A download mechanism that lets visitors save the `/creating-course` skill files (`SKILL.md` and `course_authoring_guide.md`) — either as a zip archive or individual file downloads
4. The page is linked from the site navigation so course creators can discover it

## Acceptance criteria

### Functionality
- [ ] A route and controller action serve the authoring guide page at a stable URL
- [ ] The page presents the full course format specification: folder structure, `course.json` fields, all block types with examples, validation checklist, and writing guidance
- [ ] The page includes a download button/link that provides the Claude Code skill files (`SKILL.md` and `course_authoring_guide.md`)
- [ ] The download delivers the files in a usable format (zip or individual downloads)
- [ ] The page is linked from the main site navigation
- [ ] The page is accessible without authentication (public content)

### Security
- [ ] The download endpoint only serves the intended skill files — path traversal or arbitrary file access is not possible
- [ ] No user input is used to construct file paths in the download mechanism

### Performance
- [ ] The page renders as static content with no database queries
- [ ] Downloaded files are served efficiently (appropriate caching headers, small payload)

### Testing
- [ ] Controller test verifies the page returns a 200 response
- [ ] Controller test verifies the download endpoint returns the expected file(s) with correct content type
- [ ] Test confirms the download cannot be manipulated to serve arbitrary files

## Notes

The source content already exists in `docs/creating-course/course_authoring_guide.md` and `docs/creating-course/SKILL.md`. The page can either render the markdown at build/request time or maintain a separate view template derived from it. Consider which approach keeps content in sync more easily.
