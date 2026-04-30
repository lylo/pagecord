---
name: sentry
description: Investigate and fix a Sentry issue in this codebase. Use when the user provides a Sentry issue URL or ID and wants diagnosis, a fix, verification, or a PR.
---

# Sentry

## Workflow

- Accept either a full Sentry issue URL or a short issue ID.
- Use the Sentry tools available in the environment to fetch issue details and any available analysis.
- Read the affected code paths locally and confirm the likely failure mode.
- Make the smallest defensible fix.
- Add or update tests when practical.
- Verify with the most relevant targeted tests.

## Git and output

- Create a branch named `fix/sentry-{issue-id}` when starting an implementation task.
- Summarize the issue, cause, fix, and verification.
- If the user wants a PR and GitHub tooling is available, prepare one with a short factual summary and a clear test plan.
