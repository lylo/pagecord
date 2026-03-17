---
name: fizzy
description: Interact with the Fizzy bug tracker - list, create, update, close cards, add comments, and more. Usage: /fizzy <action> [args]
allowed-tools: Bash, Read, Grep
---

# Fizzy Bug Tracker

Interact with the Fizzy bug tracker via its API.

## Setup

The Fizzy token is stored in the project `.env` file as `FIZZY_TOKEN`. Read it before making any API calls:

```bash
grep '^FIZZY_TOKEN=' /Users/olly/dev/pagecord/.env | cut -d= -f2-
```

If `FIZZY_TOKEN` is missing or empty, tell the user to add it to `.env` and stop.

**Base URL:** `https://app.fizzy.do`

## Account Slug Discovery

The account slug is required for most endpoints. Discover it on first use:

```bash
curl -s -H "Authorization: Bearer $TOKEN" -H "Accept: application/json" https://app.fizzy.do/my/identity
```

This returns `accounts[].slug` (e.g. `/897362094`). If there's only one account, use it automatically. If multiple, ask the user which one.

Cache the slug value for the duration of the conversation - don't re-fetch it on every call.

## Common Actions

All curl commands must include:
- `-H "Authorization: Bearer $TOKEN"`
- `-H "Accept: application/json"`
- `-H "Content-Type: application/json"` (for POST/PUT/PATCH)

Replace `$SLUG` with the account slug (just the number, no leading slash).

### List cards

```
GET /$SLUG/cards
```

Useful query parameters:
- `indexed_by=all` (default), `closed`, `not_now`, `stalled`, `postponing_soon`, `golden`
- `sorted_by=latest` (default), `newest`, `oldest`
- `board_ids[]=ID` - filter by board
- `tag_ids[]=ID` - filter by tag
- `assignee_ids[]=ID` - filter by assignee
- `terms[]=keyword` - search
- `creation=today`, `yesterday`, `thisweek`, `lastweek`, `thismonth`
- `assignment_status=unassigned`

Display cards in a concise table: number, title, status, tags, board name.

Follow `Link` header with `rel="next"` for pagination.

### Get a card

```
GET /$SLUG/cards/:card_number
```

Display: title, status, description (plain text from description_html), board, column, tags, assignees, steps, golden status.

### Create a card

```
POST /$SLUG/boards/:board_id/cards
```

Body: `{"card": {"title": "...", "description": "..."}}`

If the user doesn't specify a board, list boards first and ask.

### Update a card

```
PUT /$SLUG/cards/:card_number
```

Body: `{"card": {"title": "...", "description": "..."}}`

### Close a card

```
POST /$SLUG/cards/:card_number/closure
```

### Reopen a card

```
DELETE /$SLUG/cards/:card_number/closure
```

### Move to Not Now

```
POST /$SLUG/cards/:card_number/not_now
```

### Triage into a column

```
POST /$SLUG/cards/:card_number/triage
```

Body: `{"column_id": "..."}`

If column not specified, list columns for the card's board and ask.

### Send back to triage

```
DELETE /$SLUG/cards/:card_number/triage
```

### Toggle a tag

```
POST /$SLUG/cards/:card_number/taggings
```

Body: `{"tag_title": "bug"}` (leading # is stripped automatically)

### Assign/unassign a user

```
POST /$SLUG/cards/:card_number/assignments
```

Body: `{"assignee_id": "..."}`

This toggles - if already assigned, it unassigns.

### Add a comment

```
POST /$SLUG/cards/:card_number/comments
```

Body: `{"comment": {"body": "..."}}`

### List comments

```
GET /$SLUG/cards/:card_number/comments
```

Display: creator name, date, plain text body.

### List boards

```
GET /$SLUG/boards
```

### List columns for a board

```
GET /$SLUG/boards/:board_id/columns
```

### List tags

```
GET /$SLUG/tags
```

### List users

```
GET /$SLUG/users
```

### Notifications

```
GET /$SLUG/notifications
```

Display unread notifications with title, body, card link.

Mark read: `POST /$SLUG/notifications/:id/reading`
Mark all read: `POST /$SLUG/notifications/bulk_reading`

### Steps (to-do items on cards)

Create: `POST /$SLUG/cards/:card_number/steps` with `{"step": {"content": "..."}}`
Complete: `PUT /$SLUG/cards/:card_number/steps/:step_id` with `{"step": {"completed": true}}`
Delete: `DELETE /$SLUG/cards/:card_number/steps/:step_id`

### Pin/unpin

Pin: `POST /$SLUG/cards/:card_number/pin`
Unpin: `DELETE /$SLUG/cards/:card_number/pin`
List pins: `GET /my/pins`

### Mark golden

Set: `POST /$SLUG/cards/:card_number/goldness`
Remove: `DELETE /$SLUG/cards/:card_number/goldness`

## Output Guidelines

- Display card lists as concise tables (number, title, status, tags)
- For single cards, show full details in a readable format
- Strip HTML from description_html for display - show plain text
- When creating/updating, confirm the action with the card number and URL
- For errors, show the HTTP status and any error body returned
- Keep output terse - don't repeat the full API response unless asked
