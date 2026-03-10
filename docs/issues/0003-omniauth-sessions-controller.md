# [0003] OmniAuth GitHub configuration and SessionsController

## Summary

Wire up GitHub OAuth using OmniAuth so users can sign in and sign out. This includes configuring the OmniAuth provider, adding routes, building the `SessionsController`, and adding authentication helper methods to `ApplicationController`.

## Context

- **Phase:** Milestone 2 — GitHub Authentication
- **Depends on:** #0002
- **Blocks:** #0004, #0005

## What needs to happen

1. OmniAuth GitHub provider configured with client ID and secret from Rails credentials
2. OmniAuth callback route and `SessionsController` with `create` and `destroy` actions
3. CSRF protection for OmniAuth routes via `omniauth-rails_csrf_protection` gem
4. `current_user`, `authenticate_user!`, and `user_signed_in?` helpers in `ApplicationController`

## Acceptance criteria

### Functionality
- [x] Visiting the OmniAuth path redirects to GitHub's OAuth consent screen
- [x] GitHub callback creates or updates a user and sets `session[:user_id]`
- [x] Sign out clears the session and redirects to the home page
- [x] `current_user` returns the signed-in user or `nil`
- [x] `authenticate_user!` redirects unauthenticated users to the sign-in page
- [x] `user_signed_in?` is available as a view helper
- [x] Banned users are signed out and shown an appropriate message

### Security
- [x] OmniAuth routes are protected against CSRF attacks
- [x] GitHub client ID and secret are stored in Rails credentials, not in code or environment files committed to git
- [x] Session fixation is prevented by resetting the session on sign-in

### Performance
- [x] User lookup during callback uses the indexed `github_id` column

### Testing
- [ ] Controller tests cover the OAuth callback for new and returning users
- [ ] Controller tests cover sign-out
- [ ] Controller tests verify banned users cannot sign in
- [ ] Controller tests verify `authenticate_user!` redirects unauthenticated requests
