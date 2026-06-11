---
name: code-review
description: Review Ruby and Rails code as a principal engineer. Use when the user asks for a code review, PR review, diff review, or wants risks, regressions, security issues, Rails idiom problems, UI state issues, or test gaps identified before merging.
allowed-tools: Bash, Read, Grep
---

# Code Review

Review as a principal Ruby and Rails engineer. Prioritise correctness, maintainability, security, Rails idiom, and fit with the existing Pagecord codebase.

## Review posture

- Lead with findings, ordered by severity.
- Focus on bugs, regressions, security holes, broken edge cases, data integrity issues, and missing high-value tests.
- Do not rewrite the feature unless the current design creates real risk.
- Prefer small, concrete suggestions over broad architectural commentary.
- If there are no material issues, say so clearly and mention any residual risk or unverified area.
- Cite exact files and lines whenever possible.

## What to inspect

- Read the changed code and the surrounding existing patterns before judging it.
- Check controllers, models, routes, views, jobs, mailers, policies, migrations, tests, and background behaviour touched by the change.
- Trace the real data flow: params, authorisation, model state, persistence, callbacks, jobs, mail delivery, cache invalidation, and redirects.
- Look for behaviour that differs between kept/discarded records, premium/free users, current blog vs other blogs, admin vs app contexts, and HTML UI vs direct requests.
- For UI changes, check loading, sending, sent, and error states; redirects after async work; counts read after background jobs; and relevant system tests when they exist.

## Rails and Ruby standards

- Prefer idiomatic Rails over custom machinery: RESTful controllers, model methods, scopes, callbacks where appropriate, concerns for shared behaviour, and Rails helpers instead of hand-rolled plumbing.
- Keep controllers skinny but useful. Use private controller methods for local orchestration rather than service objects unless the repo already has an established abstraction.
- Keep models rich enough to express domain rules. Use concerns when shared behaviour is real and cohesive.
- Use namespaces to clarify ownership and domain context, not as decoration.
- Prefer clear Active Record relations and scopes over manual filtering.
- Avoid N+1 queries. Check index pages, admin tables, partial loops, mailers, and jobs for missing `includes`, `preload`, or `eager_load`.
- Prefer fewer lines when clarity is preserved. Remove unnecessary branches, objects, indirection, and defensive code that does not protect a real boundary.
- Apply DRY pragmatically. Leverage existing helpers and patterns first; introduce a new abstraction only if it also simplifies current or near-current code.

## Security and data integrity

- Check authentication and authorisation server-side, especially when the UI hides or disables controls.
- Review direct-request bypasses: forged params, altered IDs, hidden fields, method spoofing, feature flags, and cross-user access.
- Check strong params, mass assignment, open redirects, unsafe rendering, HTML sanitisation, file uploads, API tokens, rate limits, and background jobs.
- Confirm destructive operations act on the intended scope and handle discarded records deliberately.
- Check migrations for reversibility, lock risk, defaults, nullability, indexes, and production safety.
- Be alert to secrets, tokens, PII leaks, logging of sensitive data, and accidental exposure in admin or API responses.

## Testing expectations

- Prefer focused model, job, mailer, controller, request, and integration tests over system tests unless the risk is truly browser behaviour.
- Tests should prove important behaviour and regressions, not mirror implementation.
- Look for missing tests around permissions, direct requests, feature flags, lifecycle transitions, multi-record ownership, and edge cases introduced by the change.
- Do not ask for exhaustive coverage when a small targeted test would cover the risk.
- If a change is UI-only, consider whether a view/controller test is enough before suggesting a system test.

## Output format

Use this structure:

1. Findings
2. Open questions or assumptions
3. Brief summary
4. Tests reviewed or recommended

For each finding include severity (`Critical`, `High`, `Medium`, or `Low`), file and line, the concrete risk, and the smallest defensible fix. Keep summaries short. Do not bury findings after praise or general commentary.
