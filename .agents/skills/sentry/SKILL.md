---
name: sentry
description: Investigate and fix a Sentry issue in this codebase. Use when the user provides a Sentry issue URL or ID and wants diagnosis, a fix, verification, or a PR.
allowed-tools: Bash, Read, Grep
---

# Sentry

## Workflow

- Accept either a full Sentry issue URL or a short issue ID.
- Use `sentry-cli` first when it is installed and authenticated. Fall back to other Sentry tools only if the CLI is unavailable.
- Read the affected code paths locally and confirm the likely failure mode.
- Make the smallest defensible fix.
- Add or update tests when practical.
- Verify with the most relevant targeted tests.

## CLI access

- Check `sentry-cli --version` before calling Sentry.
- Check authentication and scopes with `sentry-cli info`; issue investigation needs read scopes such as `org:read`, `project:read`, and `event:read`.
- If the CLI only has deployment/CI scopes such as `org:ci`, ask the user to run `sentry-cli login` or otherwise configure a read-capable token locally. Never ask the user to paste an auth token in chat.
- For Pagecord, use org `pagecord`. Infer the issue ID from a Sentry URL like `https://pagecord.sentry.io/issues/7528519207`.
- `sentry-cli issues list` requires both org and project. Use it to confirm an issue is visible when the project slug is known:

```bash
sentry-cli issues list --org pagecord --project <project-slug> --id <issue-id> --max-rows 5
```

- Use `sentry-cli events list` for recent project events when the project slug is known:

```bash
sentry-cli events list --org pagecord --project <project-slug> --max-rows 20 --show-tags
```

- Sentry CLI 3.5.0 does not expose `issues info`, `issues events`, or `api`. For issue details, stack traces, per-issue events, spans, and breadcrumbs, call Sentry's read-only API with `curl` using the token from the local Sentry CLI config. Never echo the token:

```bash
TOKEN=$(awk -F= '/token/ { gsub(/[[:space:]]/, "", $2); print $2 }' ~/.sentryclirc)
curl -fsS -H "Authorization: Bearer $TOKEN" -H "Accept: application/json" \
  "https://sentry.io/api/0/issues/<issue-id>/"
curl -fsS -H "Authorization: Bearer $TOKEN" -H "Accept: application/json" \
  "https://sentry.io/api/0/issues/<issue-id>/events/?limit=5"
curl -fsS -H "Authorization: Bearer $TOKEN" -H "Accept: application/json" \
  "https://sentry.io/api/0/projects/pagecord/<project-slug>/events/<event-id>/"
```

- Prefer piping API responses through `jq` to extract only the fields needed for diagnosis.
- For performance issues, inspect `metadata`, `culprit`, `transaction`, `breakdowns`, span entries, breadcrumbs, and render partial identifiers rather than pasting raw event JSON.
- If project discovery is needed, list projects with:

```bash
sentry-cli projects list --org pagecord
```

- Redact PII in summaries. Do not paste raw stack traces unless the user explicitly asks for them.

## Git and output

- Create a branch named `sentry-<issue-id>` when starting an implementation task.
- If the user explicitly wants the older Claude branch convention, use `fix/sentry-<issue-id>` instead.
- If the user wants a PR and GitHub tooling is available, prepare one with a short factual summary and a clear test plan.
- Summarize the issue, cause, fix, verification, and PR link when applicable.
