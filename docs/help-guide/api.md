---
title: "API"
published: true
published_at: 2026-03-06T12:00:00+00:00
---

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
  https://yourblog.pagecord.com/api/posts
```

Invalid or missing tokens return `401 Unauthorized`. A revoked or expired premium subscription returns `403 Forbidden`.

## Rate limits

The API allows 60 requests per minute per blog. Exceeding this returns `429 Too Many Requests`.

## Posts

### List posts

```
GET /api/posts
```

Returns published posts by default, newest first. Filter with query parameters:

- `status` — `published` or `draft` (omit for published only)
- `published_after` — ISO 8601 timestamp
- `published_before` — ISO 8601 timestamp
- `page` — page number for pagination

Paginated results include a `Link` header with the URL for the next page (following [RFC 5988](https://tools.ietf.org/html/rfc5988)) and an `X-Total-Count` header with the total number of records. When the `Link` header is absent, you're on the last page.

### Get a post

```
GET /api/posts/:token
```

### Create a post

```
POST /api/posts
```

Parameters:

- `title` — post title
- `content` — post body (HTML by default, supports Action Text attachments)
- `content_format` — set to `markdown` to send Markdown instead of HTML
- `slug` — URL slug (auto-generated if omitted)
- `status` — `published` or `draft`
- `published_at` — ISO 8601 timestamp
- `canonical_url` — canonical URL for the post
- `tags_string` — comma-separated tags
- `hidden` — `true` to hide from the feed
- `locale` — post language code

### Update a post

```
PATCH /api/posts/:token
```

Accepts the same parameters as create.

### Delete a post

```
DELETE /api/posts/:token
```

Moves the post to trash (soft delete). Returns `204 No Content`.

## Pages

### List pages

```
GET /api/pages
```

Returns published pages by default, newest first. Accepts the same filter parameters as posts (`status`, `published_after`, `published_before`, `page`). Pagination works the same way via `Link` and `X-Total-Count` headers.

### Get a page

```
GET /api/pages/:token
```

### Create a page

```
POST /api/pages
```

Accepts the same parameters as posts, plus:

- `show_in_navigation` — `true` to show in the blog navigation

### Update a page

```
PATCH /api/pages/:token
```

### Delete a page

```
DELETE /api/pages/:token
```

Moves the page to trash (soft delete). Returns `204 No Content`. If the page is the current home page, the home page is unlinked first.

## Home page

A blog can have a single home page – a special page that replaces the default post feed.

### Get the home page

```
GET /api/home_page
```

Returns `404` if no home page is set.

### Create a home page

```
POST /api/home_page
```

Accepts the same parameters as posts. Returns `422` if a home page already exists.

### Update the home page

```
PATCH /api/home_page
```

### Remove the home page

```
DELETE /api/home_page
```

Unlinks the home page from the blog but keeps the underlying page. Returns `204 No Content`.

## Attachments

Upload images, videos, or audio files to use in your posts.

### Upload a file

```
POST /api/attachments
```

Send a `multipart/form-data` request with a `file` field:

```
curl -H "Authorization: Bearer YOUR_API_KEY" \
  -F "file=@photo.jpg" \
  https://yourblog.pagecord.com/api/attachments
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
POST /api/posts
  title=My Post
  content=<p>Check this out:</p><action-text-attachment sgid="BAh7..."></action-text-attachment>
```

The image will render inline in your post, just like images added through the editor.

### Supported file types and size limits

| Type | Formats | Max size |
|------|---------|----------|
| Images | JPEG, PNG, GIF, WebP | 10 MB |
| Video | MP4, QuickTime | 50 MB |
| Audio | MP3, WAV | 20 MB |

Unsupported content types or files exceeding the size limit return `422 Unprocessable Entity`.

## Error responses

All errors return a JSON object with an `error` or `errors` key:

```json
{ "error": "Unauthorized" }
```

| Status | Meaning |
|--------|---------|
| 401 | Missing or invalid API key |
| 403 | Premium subscription required |
| 404 | Resource not found |
| 422 | Validation failed |
| 429 | Rate limit exceeded |
