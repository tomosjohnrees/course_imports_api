# [0031] Add terms of use page

## Summary

The site needs a terms of use page setting out the rules for using the service, user responsibilities, intellectual property, liability limitations, and governing law (England and Wales). This protects the operator and sets clear expectations for users.

## Context

- **Phase:** None
- **Depends on:** None
- **Blocks:** None

## What needs to happen

1. A terms of use page at a persistent URL (e.g. `/terms`)
2. Content covering: acceptable use, user responsibilities, intellectual property, disclaimers, liability limitations, termination, and governing law
3. A footer link to the terms visible on every page

## Acceptance criteria

### Functionality
- [ ] A terms of use page is accessible at `/terms`
- [ ] The terms cover: acceptable use, user responsibilities, intellectual property, liability limitations, and governing law (England and Wales)
- [ ] A link to the terms appears in the site footer on every page

### Security
- [ ] The terms page does not expose any internal system information

### Performance
- [ ] The terms page is a static-content page with no database queries

### Testing
- [ ] The terms page renders correctly and is reachable from the footer link
