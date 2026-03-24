---
name: pagecord
description: Interact with the Pagecord API - list posts/pages, publish content, and manage blog resources. Usage: /pagecord <command> [args]
allowed-tools: Bash, Read, Glob
---

# Pagecord API

Interact with Pagecord blogs via the REST API.

## Setup

Read the API key from `.env`:

```bash
grep '^PAGECORD' /Users/olly/dev/pagecord/.env
```

Look for `PAGECORD_API_KEY` for the default blog, or `PAGECORD_{BLOG}_API_KEY` for a specific blog (e.g. `PAGECORD_HELP_API_KEY` for the help blog). Uppercase the subdomain and replace hyphens with underscores.

If no key is found, stop and tell the user to generate one via **Settings > API** in the Pagecord dashboard, then add it to `.env`.

**Base URL**: `https://api.pagecord.com`

All requests use `-H "Authorization: Bearer {API_KEY}"`.

---

## Commands

Usage: `/pagecord <command> [args]`

---

### `list posts|pages [status]`

List posts or pages for the blog. Status: `published` (default), `draft`, or `all`.

For `all`, make two requests — default (published) and `?status=draft` — and combine results.
Paginate using `?page=N` and follow `Link` headers until exhausted.

Display as a table: token (truncated to 8 chars), slug, title, status, published_at. Show total count at bottom.

---

### `get post|page <token>`

Fetch a single post or page by token.

```
GET /posts/{token}
GET /pages/{token}
```

Display all fields: token, title, slug, status, published_at, canonical_url, tags, hidden, locale, created_at, updated_at. Show first 500 chars of content HTML.

---

### `publish <file>`

Publish a local markdown file as a post.

1. Read the file
2. Parse YAML front matter: extract title, status, published_at, tags, slug if present. Map `published: true` → `status: published`, `published: false` → `status: draft`
3. If no title in front matter, extract from first `# Heading`
4. Rewrite `.md` links to `/slug` format
5. `POST /posts` with `content_format=markdown` and the full markdown content (front matter intact)
6. Report the token and URL of the created post

---

### `home`

Show the current home page.

```
GET /home_page
```

Display all fields. Show "No home page set" if 404.

---

### `status`

Test API connectivity and show a blog summary.

1. `GET /pages` — verify auth, get page count from `X-Total-Count`
2. `GET /posts` — get post count from `X-Total-Count`
3. Report: which key env var is in use, published post count, page count

---

## Output Guidelines

- Show which API key env var is being used (mask the value itself, e.g. `PAGECORD_API_KEY=***abc123`)
- Tokens: full in `get`, truncated to 8 chars in list tables
- Dates: ISO 8601
- Errors: show HTTP status code and full error body
- Never print the raw API key value
