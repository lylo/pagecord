---
title: "Search"
published: true
published_at: 2026-07-21T10:00:00+00:00
---

Let readers search your blog to find the posts and pages they're looking for.

## Adding search to your blog

Search is added as a navigation item, so it sits alongside your other header links.

1. Go to **Settings** → **Navigation**
2. Choose **Search**
3. Click **Add to Navigation**

A search icon appears in your header. Readers click it to open your search page, and you can drag it into whatever position you like.

## Adding a search box to a page

You can also put a search box directly into a page using the `{{ search }}` [dynamic variable](dynamic-variables-for-pages.md). It works well on an archive page, where readers are already hunting for something specific.

Paste it into the page content, not inside a code block in the editor:

```
{{ search }}
```

It searches exactly as the search page does, so there's no need to add both a navigation item and an embedded box unless you want them.

## How search works

Search looks across the titles and content of your published posts and pages. Results are ordered with the most recent first.

## Searching for an exact phrase

To match an exact phrase, wrap it in double quotes:

- `coffee shop` finds posts that mention both words anywhere
- `"coffee shop"` finds posts where those words appear together, in that order
