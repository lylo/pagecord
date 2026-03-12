---
title: "API"
published: true
published_at: 2026-03-06T12:00:00+00:00
---

**The API is not live yet — coming soon.** This page documents what's on the way so you can plan ahead.

Premium feature. Manage your blog posts programmatically using the Pagecord API. Useful for publishing from scripts, Obsidian, Shortcuts, LLMs, or any tool that can make HTTP requests.

## Getting an API key

1. Go to **Settings > API** in your dashboard
2. Click **Generate API Key**
3. Copy the key and store it somewhere safe — you won't be able to see it again

You can regenerate or revoke your key at any time from the same page.

## Authentication

All API requests require a Bearer token in the `Authorization` header:

```
curl -H "Authorization: Bearer YOUR_API_KEY" \
  https://api.pagecord.com/posts
```

Invalid or missing tokens return `401 Unauthorized`. A revoked or expired premium subscription returns `403 Forbidden`.

## Rate limits

The API allows 60 requests per minute per blog. Exceeding this returns `429 Too Many Requests`.

## Posts

### List posts

```
GET /posts
```

Returns published posts by default, newest first. Filter with query parameters:

- `status` — `published` or `draft` (omit for published only)
- `published_after` — ISO 8601 timestamp (e.g. `2026-03-11T00:00:00Z`). Returns `400` if malformed.
- `published_before` — ISO 8601 timestamp. Returns `400` if malformed.
- `page` — page number for pagination. Returns `400` if out of range.

Paginated results include a `Link` header with the URL for the next page (following [RFC 5988](https://tools.ietf.org/html/rfc5988)) and an `X-Total-Count` header with the total number of records. When the `Link` header is absent, you're on the last page.

### Get a post

```
GET /posts/:token
```

### Create a post

```
POST /posts
```

Parameters:

- `title` — post title
- `content` — post body (HTML by default, supports Action Text attachments)
- `content_format` — set to `markdown` to send Markdown instead of HTML (see [Markdown & front matter](#markdown--front-matter))
- `slug` — URL slug (auto-generated if omitted)
- `status` — `published` or `draft`
- `published_at` — ISO 8601 timestamp
- `canonical_url` — canonical URL for the post
- `tags` — comma-separated tags
- `hidden` — `true` to hide from the feed
- `locale` — post language code

### Update a post

```
PATCH /posts/:token
```

Accepts the same parameters as create.

### Delete a post

```
DELETE /posts/:token
```

Moves the post to trash (soft delete). Returns `204 No Content`.

## Pages

### List pages

```
GET /pages
```

Returns published pages by default, newest first. Accepts the same filter parameters as posts (`status`, `published_after`, `published_before`, `page`). Pagination works the same way via `Link` and `X-Total-Count` headers.

### Get a page

```
GET /pages/:token
```

### Create a page

```
POST /pages
```

Accepts the same parameters as posts.


### Update a page

```
PATCH /pages/:token
```

### Delete a page

```
DELETE /pages/:token
```

Moves the page to trash (soft delete). Returns `204 No Content`. If the page is the current home page, the home page is unlinked first.

## Home page

A blog can have a single home page – a special page that replaces the default post feed.

### Get the home page

```
GET /home_page
```

Returns `404` if no home page is set.

### Create a home page

```
POST /home_page
```

Accepts the same parameters as posts. Creates a new page and sets it as the home page. If a home page already exists, the API returns `422 Unprocessable Entity`.

### Update the home page

```
PATCH /home_page
```

### Remove the home page

```
DELETE /home_page
```

Unlinks the home page from the blog but keeps the underlying page. Returns `204 No Content`.

## Attachments

Upload images, videos, or audio files to use in your posts.

### Upload a file

```
POST /attachments
```

Send a `multipart/form-data` request with a `file` field:

```
curl -H "Authorization: Bearer YOUR_API_KEY" \
  -F "file=@photo.jpg" \
  https://api.pagecord.com/attachments
```

Returns `201 Created` with:

```json
{
  "attachable_sgid": "BAh7...",
  "url": "https://..."
}
```

### Using attachments in posts

Use the returned `attachable_sgid` in your post content with an Action Text attachment tag:

```
POST /posts
  title=My Post
  content=<p>Check this out:</p><action-text-attachment sgid="BAh7..."></action-text-attachment>
```

The image will render inline in your post, just like images added through the editor.

### Reusing attachments across updates

Each `attachable_sgid` is stable — upload the file once, then reuse the same sgid every time you update the post. Re-uploading an unchanged image creates a new blob and **permanently deletes** the old one.

The `content` field returned by `GET`, `POST`, and `PATCH` responses contains the stored HTML with sgids. Extract and cache these for future updates. Only call `POST /attachments` when you have a genuinely new file to attach.

### Supported file types and size limits

| Type | Formats | Max size |
|------|---------|----------|
| Images | JPEG, PNG, GIF, WebP | 10 MB |
| Video | MP4, QuickTime | 50 MB |
| Audio | MP3, WAV | 20 MB |

Unsupported content types or files exceeding the size limit return `422 Unprocessable Entity`.

## Markdown & front matter

Set `content_format` to `markdown` on any create or update endpoint to send Markdown instead of HTML. The API converts it to HTML before saving.

You can also include YAML front matter to set post attributes inline:

```
POST /posts
  content_format=markdown
  content=
---
title: My Post
slug: my-post
status: published
tags:
  - ruby
  - rails
published_at: '2026-03-11'
---
Hello **world**
```

Supported front matter fields: `title`, `slug`, `status`, `published_at` (or `date`), `canonical_url`, `locale`, `hidden`, `tags`.

Explicit parameters always take priority over front matter values. For example, passing `title=Explicit` with front matter containing `title: From FM` will use "Explicit".

Malformed YAML front matter returns `422` with an error message.

## Error responses

All errors return a JSON object with an `error` or `errors` key:

```json
{ "error": "Unauthorized" }
```

| Status | Meaning |
|--------|---------|
| 400 | Bad request — invalid timestamp, out-of-range page, or invalid status value |
| 401 | Missing or invalid API key |
| 403 | Premium subscription required |
| 404 | Resource not found |
| 422 | Validation failed — includes invalid front matter |
| 429 | Rate limit exceeded |
