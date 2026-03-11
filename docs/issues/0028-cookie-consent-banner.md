# [0028] Add cookie consent banner

## Summary

UK law (PECR) requires opt-in consent before setting non-essential cookies. The site needs a cookie consent banner that blocks non-essential cookies until the user actively agrees, and lets them change their mind later. Without this, the site is non-compliant with PECR and exposed to ICO enforcement.

## Context

- **Phase:** None
- **Depends on:** #0029 (need to know which cookies are non-essential before implementing consent)
- **Blocks:** None

## What needs to happen

1. A cookie consent banner displayed on first visit with clear accept/reject options
2. Non-essential cookies are blocked until the user gives affirmative consent
3. The user's consent preference is persisted (via a strictly-necessary cookie) and respected on subsequent visits
4. A way for users to revisit and change their cookie preferences at any time

## Acceptance criteria

### Functionality
- [x] A cookie consent banner appears on the first page load for new visitors
- [x] Non-essential cookies and scripts are not set or loaded until the user clicks "Accept"
- [x] Clicking "Reject" or dismissing the banner results in only strictly necessary cookies being set
- [x] The user's choice is remembered across sessions
- [x] A link or button (e.g. in the footer) allows users to reopen the consent dialog and change their preference

### Security
- [x] The consent preference cookie cannot be spoofed to grant consent on behalf of another user
- [x] No third-party scripts are loaded before consent is recorded

### Performance
- [x] The consent banner renders without additional blocking network requests
- [x] The banner uses inline or existing CSS — no new external stylesheets

### Testing
- [x] Banner appears for a new visitor with no prior consent cookie
- [x] Banner does not reappear after the user makes a choice
- [x] Non-essential cookies are verified absent when consent is rejected
