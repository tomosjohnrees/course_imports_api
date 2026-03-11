# [0030] Add privacy policy page

## Summary

UK GDPR requires a clear, accessible privacy policy explaining what personal data is collected, why, the legal basis, retention periods, and user rights. Since the app uses GitHub OAuth, the data footprint is small (username, email, avatar), but it still needs formal disclosure. The page must be publicly accessible and linked from the site footer.

## Context

- **Phase:** None
- **Depends on:** #0029 (cookie audit informs what the policy must disclose about cookies)
- **Blocks:** None

## What needs to happen

1. A privacy policy page at a persistent URL (e.g. `/privacy`)
2. Content covering: data collected, processing purposes, legal basis (UK GDPR Article 6), data retention, third-party sharing, cookie usage, user rights, and data controller contact details
3. A footer link to the privacy policy visible on every page

## Acceptance criteria

### Functionality
- [ ] A privacy policy page is accessible at `/privacy`
- [ ] The policy covers: what data is collected, why, the legal basis, retention period, third-party sharing, cookies, and user rights (access, rectification, erasure, portability, complaint to the ICO)
- [ ] The policy identifies the data controller and provides contact details
- [ ] A link to the privacy policy appears in the site footer on every page

### Security
- [ ] The privacy policy does not inadvertently disclose internal system details or infrastructure information

### Performance
- [ ] The privacy policy page is a static-content page with no database queries

### Testing
- [ ] The privacy policy page renders correctly and is reachable from the footer link
- [ ] The content is reviewed to confirm it covers all required UK GDPR disclosures
