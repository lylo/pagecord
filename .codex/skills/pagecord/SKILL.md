---
name: pagecord
description: Interact with the Pagecord API for a blog. Use when the user wants to inspect posts or pages, publish content through the API, check API connectivity, or inspect the home page.
---

# Pagecord API

Use the public API at `https://api.pagecord.com`.

## Setup

- Read API keys from `/Users/olly/dev/pagecord/.env`.
- Prefer `PAGECORD_API_KEY` for the default blog.
- For a specific blog, look for `PAGECORD_{BLOG}_API_KEY` with the subdomain uppercased and hyphens replaced by underscores.
- If no key exists, stop and tell the user to create one in `Settings > API`.

All requests use `Authorization: Bearer {API_KEY}`. Never print the raw key.

## Common operations

- List posts or pages, optionally by status
- Fetch a single post or page by token
- Show the home page
- Publish a local markdown file as a post
- Check API connectivity and report counts

When listing content, present a concise table. When publishing markdown, preserve front matter and send `content_format=markdown`.
