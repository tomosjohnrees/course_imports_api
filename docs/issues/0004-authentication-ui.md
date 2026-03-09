# [0004] Authentication UI — sign in and sign out flow

## Summary

Build the minimal UI for GitHub authentication: a home page with a "Sign in with GitHub" button when signed out, and a signed-in state showing the user's GitHub username, avatar, and a sign-out link. Includes redirect-back-after-sign-in behaviour.

## Context

- **Phase:** Milestone 2 — GitHub Authentication
- **Depends on:** #0003
- **Blocks:** #0005

## What needs to happen

1. A home page that shows a "Sign in with GitHub" button when the user is not signed in
2. A signed-in state displaying the user's GitHub avatar, username, and a "Sign out" link
3. Redirect back to the originally requested page after successful sign-in

## Acceptance criteria

### Functionality
- [ ] Home page displays a "Sign in with GitHub" button when no user is signed in
- [ ] After sign-in, the page shows the user's GitHub avatar and username
- [ ] A "Sign out" link is visible when signed in and works correctly
- [ ] After signing in, the user is redirected back to the page they were trying to access (if any)
- [ ] The layout works for both signed-in and signed-out states without visual glitches

### Security
- [ ] The sign-in button uses a `POST` form (not a `GET` link) to satisfy CSRF requirements
- [ ] No sensitive data (tokens, internal IDs) is rendered in the HTML

### Performance
- [ ] Pages load without unnecessary database queries beyond fetching the current user

### Testing
- [ ] System or integration tests cover the sign-in and sign-out user flow
- [ ] Tests verify the redirect-back-after-sign-in behaviour
