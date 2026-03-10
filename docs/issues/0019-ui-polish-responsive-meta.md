# [0019] UI polish, responsive layout, and meta tags

## Summary

Polish the public-facing pages for a clean, calm, minimal design consistent with the desktop app's aesthetic. Make the layout responsive for mobile readability, and add proper `<title>` and meta description tags on all public pages for SEO and sharing.

## Context

- **Phase:** Milestone 4 — Browse & Search
- **Depends on:** #0015, #0016, #0017, #0018
- **Blocks:** None

## What needs to happen

1. A clean, minimal visual design across all public pages (index, detail, search results)
2. Responsive layout that works on mobile screens (the desktop app is the primary target, but the web registry should be readable on phones)
3. Correct `<title>` tags and `<meta name="description">` on all public pages (index, detail, search results)

## Acceptance criteria

### Functionality
- [x] All public pages have a consistent, clean visual design
- [x] The layout is readable and usable on mobile screen sizes (320px–768px)
- [x] Navigation works on both desktop and mobile
- [x] Every public page has a unique, descriptive `<title>` tag
- [x] Every public page has a `<meta name="description">` tag with relevant content
- [x] Course detail pages include the course title in the `<title>` tag

### Security
- [x] No user-generated content is rendered unescaped in meta tags or HTML attributes

### Performance
- [x] CSS is minimal and loads quickly (no heavy framework unless already in use)
- [x] Images (e.g. avatars) use appropriate sizing and lazy loading where applicable
- [x] No layout shifts on page load

### Testing
- [x] Visual review of all public pages at desktop and mobile breakpoints
- [x] Tests verify `<title>` and meta description tags are present and correct on key pages
