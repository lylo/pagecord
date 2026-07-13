---
name: fizzy
description: Interact with the Fizzy tracker for Pagecord work. Use when the user asks to list, create, update, move, close, comment on, or inspect Fizzy cards, boards, tags, users, steps, pins, or notifications.
allowed-tools: Bash, Read, Grep
---

# Fizzy

Use the Fizzy API through the local wrapper when available. Fall back to `curl` only when the wrapper is missing.

## Transport

- Prefer `/Users/olly/.local/bin/fizzy METHOD /path [json]` when the file exists.
- Do not create the wrapper inside this repo; it is a local operator tool.
- The wrapper already reads `FIZZY_TOKEN`, pins requests to `https://app.fizzy.do`, and adds the usual JSON/auth headers.
- Use raw `curl` as a fallback only when `/Users/olly/.local/bin/fizzy` is not executable.
- When the wrapper is available, do not ask for per-URL approvals. Use the stable command prefix `/Users/olly/.local/bin/fizzy`.

Examples:

- `/Users/olly/.local/bin/fizzy GET /my/identity`
- `/Users/olly/.local/bin/fizzy GET /6102591/cards/318`
- `/Users/olly/.local/bin/fizzy POST /6102591/cards/318/triage '{"column_id":"..."}'`

## Setup

- Read `FIZZY_TOKEN` from `/Users/olly/dev/pagecord/.env`.
- Base URL: `https://app.fizzy.do`.
- If the token is missing, stop and say so.
- Discover the account slug from `GET /my/identity` and reuse it for the rest of the task.
- If there is only one account, use it automatically. If there are multiple accounts, ask the user which one.

Every API call should include:

- `Authorization: Bearer $TOKEN`
- `Accept: application/json`
- `Content-Type: application/json` for write requests

Card descriptions should be sent as HTML, not Markdown. Fizzy stores descriptions through ActionText; Markdown is shown as plain text, while HTML renders correctly in `description_html`. Use standard tags such as `<h2>`, `<p>`, `<ul>`, `<li>`, and `<code>`. Avoid task-list checkbox inputs because ActionText strips the `<input>` elements.

## Common operations

- List cards: `GET /$SLUG/cards`
- Get card: `GET /$SLUG/cards/:card_number`
- Create card: `POST /$SLUG/boards/:board_id/cards` with `{"card":{"title":"...","description":"..."}}`
- Update card: `PUT /$SLUG/cards/:card_number`
- Delete card: `DELETE /$SLUG/cards/:card_number` (permanent, returns 204; prefer Close for normal workflow)
- Close card: `POST /$SLUG/cards/:card_number/closure`
- Reopen card: `DELETE /$SLUG/cards/:card_number/closure`
- Move card into a column: `POST /$SLUG/cards/:card_number/triage` with `{"column_id":"..."}`
- Send card back to triage: `DELETE /$SLUG/cards/:card_number/triage`
- Move to Not Now: `POST /$SLUG/cards/:card_number/not_now`
- Toggle tag: `POST /$SLUG/cards/:card_number/taggings` with `{"tag_title":"bug"}`
- Toggle assignment: `POST /$SLUG/cards/:card_number/assignments` with `{"assignee_id":"..."}`
- Add comment: `POST /$SLUG/cards/:card_number/comments` with `{"comment":{"body":"..."}}` (HTML/Action Text, same as descriptions; the key is `body`, not `content` or `description`)
- List comments: `GET /$SLUG/cards/:card_number/comments`
- Delete comment: `DELETE /$SLUG/cards/:card_number/comments/:comment_id` (returns 204; handy for cleaning up probe comments)
- List boards: `GET /$SLUG/boards`
- List columns: `GET /$SLUG/boards/:board_id/columns`
- List tags: `GET /$SLUG/tags`
- List users: `GET /$SLUG/users`
- List notifications: `GET /$SLUG/notifications`
- Mark notification read: `POST /$SLUG/notifications/:id/reading`
- Mark all notifications read: `POST /$SLUG/notifications/bulk_reading`
- Pin card: `POST /$SLUG/cards/:card_number/pin`
- Unpin card: `DELETE /$SLUG/cards/:card_number/pin`
- List pins: `GET /my/pins`
- Mark golden: `POST /$SLUG/cards/:card_number/goldness`
- Remove golden: `DELETE /$SLUG/cards/:card_number/goldness`

## Steps

- Create: `POST /$SLUG/cards/:card_number/steps` with `{"step":{"content":"..."}}`
- Complete: `PUT /$SLUG/cards/:card_number/steps/:step_id` with `{"step":{"completed":true}}`
- Delete: `DELETE /$SLUG/cards/:card_number/steps/:step_id`

## Listing and filtering

Useful `GET /$SLUG/cards` query params:

- `indexed_by=all`, `closed`, `not_now`, `stalled`, `postponing_soon`, or `golden`
- `sorted_by=latest`, `newest`, or `oldest`
- `board_ids[]=ID`
- `tag_ids[]=ID`
- `assignee_ids[]=ID`
- `terms[]=keyword`
- `creation=today`, `yesterday`, `thisweek`, `lastweek`, or `thismonth`
- `assignment_status=unassigned`

Follow `Link` headers with `rel="next"` for pagination when needed.

## Output

- For card lists, show a concise table with number, title, status, tags, and board.
- For single-card reads, summarize title, status, description, board, column, tags, assignees, steps, golden status, and URL.
- Strip HTML from `description_html` for display.
- When creating or updating, confirm the action with the card number and URL.
- For errors, show the HTTP status and any error body.
- Keep output terse unless the user asks for raw API details.
