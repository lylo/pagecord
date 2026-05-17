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

## Changing the "Read more" text

Pagecord translates "Read more" based on your blog language. If you want different wording, you can hide the original text and replace it with custom CSS.

Go to **Settings > Appearance**, then add this to the Custom CSS box:

```css
.excerpt-read-more a {
  font-size: 0;
}

.excerpt-read-more a::after {
  content: "Continue reading";
  font-size: 0.875em;
}
```

Change `Continue reading` to whatever text you want.

This changes the visible label. The underlying link still uses Pagecord's translated "Read more" text.

## Notes

The marker must be on its own line. If you put it in the middle of a paragraph, list item, blockquote, or table, Pagecord will treat it as normal text.
