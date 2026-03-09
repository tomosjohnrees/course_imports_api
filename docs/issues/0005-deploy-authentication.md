# [0005] Deploy and verify GitHub authentication in production

## Summary

Add the GitHub OAuth credentials to the production environment and deploy the authentication feature. Verify the full sign-in and sign-out flow works against real GitHub OAuth in production.

## Context

- **Phase:** Milestone 2 — GitHub Authentication
- **Depends on:** #0004
- **Blocks:** #0006

## What needs to happen

1. `GITHUB_CLIENT_ID` and `GITHUB_CLIENT_SECRET` added to `.kamal/secrets`
2. A production deploy via `kamal deploy`
3. Manual verification that the full OAuth flow works end-to-end in production

## Acceptance criteria

### Functionality
- [ ] A real GitHub account can sign in via the production site
- [ ] A `User` record is created with an encrypted token after first sign-in
- [ ] Sign out works and clears the session
- [ ] Subsequent sign-ins update the existing user record rather than creating duplicates

### Security
- [ ] GitHub OAuth secrets are in `.kamal/secrets` and not committed to the repository
- [ ] The OAuth callback URL in the GitHub OAuth app settings matches the production domain
- [ ] HTTPS is used for the entire OAuth flow

### Performance
- [ ] The sign-in flow completes without noticeable delay beyond the GitHub redirect

### Testing
- [ ] Manual smoke test of sign-in and sign-out on the production domain

## Notes

Requires a GitHub OAuth App to be created at https://github.com/settings/developers with the production callback URL configured.
