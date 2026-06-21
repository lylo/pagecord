---
title: "Publishing with Micropub"
published: true
published_at: 2026-06-21T00:00:00+00:00
---

Micropub lets compatible writing apps publish posts to your Pagecord blog. It is useful if you write in an app such as iA Writer and want to send drafts or published posts straight to Pagecord.

Micropub uses your Pagecord API key, so it is a Premium feature.

<div>
{{ table_of_contents | heading: "Table of Contents" }}
</div>

## Setup

First, [enable the API](/api) in your Pagecord blog settings and copy your API key.

Your Micropub endpoint is:

```text
https://api.pagecord.com/micropub
```

Your media endpoint is:

```text
https://api.pagecord.com/micropub/media
```

Pagecord includes a `<link rel="micropub">` tag in your blog HTML, so apps that support endpoint discovery can find the endpoint from your blog URL.

If an app asks for a profile, site, or blog URL, enter your public blog URL. If it explicitly asks for a Micropub endpoint, enter the API URL above.

## Using iA Writer

iA Writer has built-in Micropub support on Mac, iPhone, and iPad.

1. Generate or copy your Pagecord API key from Settings > API.
2. In iA Writer, go to Settings > Publishing.
3. Add a Micropub account.
4. Choose manual token entry.
5. Enter your blog URL, for example `https://example.pagecord.com`, and paste your Pagecord API key. Do not enter `https://api.pagecord.com/micropub` unless iA Writer explicitly asks for a Micropub endpoint.
6. In the Micropub publishing options, set the format to Markdown.

You can then publish from iA Writer as a draft or published post, depending on the options iA Writer shows for your device.

## Supported Features

Pagecord supports creating and updating posts with:

- Title
- Markdown or HTML content
- Draft or published status
- Tags
- Slug
- Published date
- Image uploads through the media endpoint
- Image descriptions from apps, stored as captions

Pagecord does not currently support cross-posting targets through Micropub. The `syndicate-to` response is intentionally empty.

## Authentication

Send your API key as a Bearer token:

```text
Authorization: Bearer YOUR_API_KEY
```

Micropub form requests may also send the same token as `access_token`.

## Creating Posts

Form-encoded request:

```text
POST /micropub
Content-Type: application/x-www-form-urlencoded

h=entry&name=My+Post&content=Hello+**world**&category[]=writing
```

JSON request:

```json
{
  "type": ["h-entry"],
  "properties": {
    "name": ["My Post"],
    "content": ["Hello **world**"],
    "category": ["writing"],
    "post-status": ["draft"]
  }
}
```

On success, Pagecord returns `201 Created` with a `Location` header pointing to the post.

## Updating Posts

Updates use JSON and require the post URL.

```json
{
  "action": "update",
  "url": "https://example.pagecord.com/my-post",
  "replace": {
    "content": ["Updated **content**"],
    "post-status": ["published"]
  }
}
```

Tags can be added or removed:

```json
{
  "action": "update",
  "url": "https://example.pagecord.com/my-post",
  "add": {
    "category": ["notes"]
  },
  "delete": {
    "category": ["draft"]
  }
}
```

## Images

Upload images before creating or updating a post:

```text
POST /micropub/media
Content-Type: multipart/form-data

file=@photo.jpg
```

On success, Pagecord returns `201 Created` with a `Location` header. Use that URL in your Markdown content or as a Micropub `photo` property.

## Source Queries

Apps can ask Pagecord for a post's source properties:

```text
GET /micropub?q=source&url=https://example.pagecord.com/my-post
```

To request specific properties only, add `properties[]=name&properties[]=content`.
