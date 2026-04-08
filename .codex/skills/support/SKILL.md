---
name: support
description: Investigate a customer support email and draft a reply. Use when the user pastes a customer message, bug report, billing question, feature request, or how-to question.
---

# Support

Provide two sections:

1. `Internal Notes`
2. `Draft Response`

## Workflow

- Classify the request: bug, how-to, feature request, or account/billing.
- Investigate the relevant code paths in the repo.
- When helpful, check existing help content before inventing an answer.
- For bugs, identify the likely root cause or the narrowest plausible set of causes.
- For billing, remember Paddle handles payment processing.
- For subscription/trial questions, check the premium/trial rules in the repo.

## Output rules

- `Internal Notes` should be concise and practical: findings, likely cause, relevant files, and any follow-up commands if needed.
- `Draft Response` should be plain text, customer-ready, and specific to the issue.
- Keep the draft friendly and direct.
- Use en-dashes, not em dashes.
