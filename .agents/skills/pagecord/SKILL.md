---
name: pagecord
description: Interact with the Pagecord API for a blog. Use when the user wants to inspect posts or pages, publish content through the API, check API connectivity, or inspect the home page.
allowed-tools: Bash, Read, Glob
---

# Pagecord API

Use the public API at `https://api.pagecord.com`.

## Setup

- Read API keys from `/Users/olly/dev/pagecord/.env`.
- Prefer `PAGECORD_API_KEY` for the default blog.
- For a specific blog, look for `PAGECORD_{BLOG}_API_KEY` with the subdomain uppercased and hyphens replaced by underscores.
- If no key exists, stop and tell the user to create one in `Settings > API`.
- All requests use `Authorization: Bearer {API_KEY}`. Never print the raw key.
- Show which API key env var is in use, masked if needed.

## Operations

### List posts or pages

Use `GET /posts` or `GET /pages`. Status may be `published`, `draft`, or `all`.

For `all`, make one published request and one `?status=draft` request, then combine results. Paginate using `page=N` or `Link` headers until exhausted. Display a concise table with token, slug, title, status, and published date.

### Get a post or page

Use `GET /posts/{token}` or `GET /pages/{token}`. Show token, title, slug, status, published date, canonical URL, tags, hidden state, locale, created/updated dates, and a short content preview.

### Publish markdown

When publishing a local markdown file as a post:

1. Read the file.
2. Parse YAML front matter for title, status, published date, tags, and slug.
3. Map `published: true` to `status: published` and `published: false` to `status: draft`.
4. If no title exists in front matter, use the first `# Heading`.
5. Rewrite local `.md` links to `/slug` format.
6. `POST /posts` with the full markdown content and `content_format=markdown`.
7. Report the created token and URL.

Preserve front matter when sending markdown to the API.

### Home page

Use `GET /home_page`. Show all fields. If the response is 404, report that no home page is set.

### Status

Check API connectivity by fetching page and post counts from `X-Total-Count`, then report the key env var in use, published post count, and page count.

## Output

- Tokens are full for single-item reads and truncated in list tables.
- Dates should be ISO 8601.
- For errors, show the HTTP status and response body.
- Never print the raw API key value.
