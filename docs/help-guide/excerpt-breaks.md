---
title: "Using excerpt breaks"
published: true
published_at: 2026-05-17T00:00:00+00:00
---

Excerpt breaks let you show a short teaser on your blog home page, with the rest of the post available on the full post page.

## Adding an excerpt break

Put one of these markers on its own line where you want the teaser to end:

```text
{{ more }}
```

or:

```text
<!--more-->
```

Everything before the marker appears as the teaser. Everything after it is hidden from the stream view until someone opens the full post.

## Where excerpts appear

Excerpt breaks affect your blog's post lists:

- **Stream layout** shows the teaser followed by a "Read more" link
- **Cards layout** uses the teaser as the card preview text

The full post page, RSS feed, and email digests still include the full post content. The marker itself is stripped before the post is shown to readers.

## Notes

The marker must be on its own line. If you put it in the middle of a paragraph, list item, blockquote, or table, Pagecord will treat it as normal text.
