# [0032] Add account and data deletion

## Summary

UK GDPR gives users the right to erasure ("right to be forgotten"). The site must provide a way for users to delete their account and all associated personal data. Deletion requests must be fulfilled within 30 days. This is a legal requirement, not a nice-to-have.

## Context

- **Phase:** None
- **Depends on:** None
- **Blocks:** None

## What needs to happen

1. A user-facing mechanism to request account deletion (e.g. a button in account settings)
2. Deletion logic that removes or anonymises all personal data across primary, cache, and queue databases
3. Confirmation flow so users don't accidentally delete their account

## Acceptance criteria

### Functionality
- [ ] Users can initiate account deletion from their account settings
- [ ] A confirmation step prevents accidental deletion
- [ ] Account deletion removes the user record and anonymises or deletes all associated course submissions
- [ ] After deletion, the user is logged out and cannot log back in to the deleted account

### Security
- [ ] Only the authenticated user can delete their own account — no user can trigger deletion of another account
- [ ] Personal data is removed from all database tables (users, courses, any cached data)
- [ ] Deletion is irreversible and no personal data remains recoverable

### Performance
- [ ] Deletion of associated records is handled in a background job if the user has many submissions, to avoid request timeouts

### Testing
- [ ] Account deletion removes the user record from the database
- [ ] Associated course submissions are deleted or anonymised after account deletion
- [ ] A deleted user cannot authenticate again with the same GitHub account (or if they can, they get a fresh account with no prior data)
