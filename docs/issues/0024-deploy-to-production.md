# [0024] Deploy application to production and verify

## Summary

Run the initial Kamal deployment to get the Rails app live on the production server. Verify the health check, HTTPS, and PostgreSQL are all working correctly. This is the integration checkpoint for Milestone 1 — everything is working end-to-end.

## Context

- **Phase:** Milestone 1 — Project Setup & Deployment Pipeline
- **Depends on:** #0023
- **Blocks:** #0001

## What needs to happen

1. `kamal setup` run successfully — Docker installed on the server, PostgreSQL accessory started
2. `kamal deploy` run successfully — app image built, pushed, and running on the server
3. The app is reachable at the production domain over HTTPS
4. PostgreSQL is running and accessible from the app container

## Acceptance criteria

### Functionality
- [x] `kamal setup` completes without errors
- [x] `kamal deploy` completes without errors and the app container is running
- [x] The `/up` health check endpoint responds with HTTP 200
- [x] The app is accessible at the production domain in a browser

### Security
- [x] HTTPS is working with a valid Let's Encrypt certificate (no browser warnings)
- [x] HTTP requests redirect to HTTPS
- [x] PostgreSQL is not accessible from outside the server (port 5432 is firewalled)

### Performance
- [x] The health check responds within 1 second
- [x] `kamal deploy` from local machine completes within a reasonable time (image build + push + deploy)

### Testing
- [x] Manual verification of `/up` returning 200 via `curl https://<domain>/up`
- [x] Manual verification of HTTPS certificate validity in browser
- [x] `kamal app exec 'bin/rails db:version'` confirms the database is accessible from the app container

## Notes

After this issue is complete, every subsequent milestone can be deployed to production immediately. The deployment pipeline is the foundation for continuous delivery throughout the project.
