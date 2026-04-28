---
name: fizzy
description: Interact with the Fizzy tracker for Pagecord work. Use when the user asks to list, create, update, move, close, comment on, or inspect Fizzy cards or boards.
---

# Fizzy

Use the Fizzy API via `curl`.

## Setup

- Read `FIZZY_TOKEN` from `/Users/olly/dev/pagecord/.env`.
- Base URL: `https://app.fizzy.do`
- If the token is missing, stop and say so.
- Discover the account slug from `GET /my/identity` and reuse it for the rest of the task.

Every API call should include:

- `Authorization: Bearer $TOKEN`
- `Accept: application/json`
- `Content-Type: application/json` for write requests

## Common operations

- List boards: `GET /$SLUG/boards`
- List columns: `GET /$SLUG/boards/:board_id/columns`
- List cards: `GET /$SLUG/cards`
- Get card: `GET /$SLUG/cards/:card_number`
- Create card: `POST /$SLUG/boards/:board_id/cards` with `{"card":{"title":"...","description":"..."}}`
- Update card: `PUT /$SLUG/cards/:card_number`
- Move card into a column: `POST /$SLUG/cards/:card_number/triage` with `{"column_id":"..."}`
- Add comment: `POST /$SLUG/cards/:card_number/comments`
- Close card: `POST /$SLUG/cards/:card_number/closure`
- Reopen card: `DELETE /$SLUG/cards/:card_number/closure`

If the user does not specify a board for creation, list boards first. If the user wants a move but does not specify a column, list columns for that board first.

For card lists, show a concise table with number, title, status, tags, and board. For single-card reads, summarize the key fields instead of dumping raw JSON.
