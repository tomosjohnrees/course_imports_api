# [0029] Audit and categorise all cookies

## Summary

Before implementing cookie consent, the site needs a complete inventory of every cookie it sets — session cookies, Solid Cache cookies, any analytics or preference cookies — categorised as strictly necessary or non-essential. This audit determines what the consent banner needs to control and what the privacy policy must disclose.

## Context

- **Phase:** None
- **Depends on:** None
- **Blocks:** #0028

## What needs to happen

1. A documented list of every cookie the application sets, including name, purpose, duration, and category (strictly necessary vs non-essential)
2. Identification of any third-party scripts or services that set cookies
3. Confirmation of which cookies can be set without consent (strictly necessary) and which require opt-in

## Acceptance criteria

### Functionality
- [ ] A cookie audit document exists (e.g. `docs/cookie-audit.md`) listing every cookie with name, purpose, duration, and category
- [ ] Session cookies are confirmed as strictly necessary
- [ ] Any analytics, tracking, or preference cookies are identified and flagged as requiring consent

### Security
- [ ] No cookies are found to contain sensitive data in plain text (e.g. tokens, emails)

### Performance
- [ ] No performance criteria — this is a documentation task

### Testing
- [ ] The audit is verified against a fresh browser session by inspecting cookies in DevTools
