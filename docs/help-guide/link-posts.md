---
title: "Link posts"
published: true
published_at: 2026-10-14T00:00:00+00:00
---

A link post is a post whose title links to another page on the web, with your own take on it underneath. It's the format made famous by [Daring Fireball](https://daringfireball.net).

## Writing a link post

Write your post as normal, then open **Post settings** and paste the address into **Link URL**. A link post needs a title, since the title is the link. Pages can't be link posts.

The rest is a normal post, with comments, likes, tags and everything else. To turn it back into a normal post, clear **Link URL**.

## Where the title goes

On your home page, on the post page and in emails to your subscribers, a link post's title links to the page you're writing about, with a small ↗ after it. Readers reach the post itself through the date at the foot of the post.

In the title, cards and gallery layouts, and in `{{ posts }}` and `{{ posts_by_year }}`, the title still links to your post.

## In your RSS feed

Feed readers open the page you're writing about when someone clicks a link post's title. The post ends with 🔗 and its own address, so readers can find their way back to your blog.

To offer a feed of just your own writing, leave link posts out with `link_posts=false`:

```javascript
https://yourusername.pagecord.com/feed.xml?link_posts=false
```

Or use `link_posts=true` for a feed of just your link posts. See [RSS feeds](rss-feeds.md) for more.

## On your pages

The same filter works with dynamic variables. An archive without link posts:

```javascript
{{ posts_by_year | link_posts: false }}
```

See [Dynamic variables for pages](dynamic-variables-for-pages.md) for more.

## Styling link posts

Link posts carry a `link-post` class. To give their titles a light dotted underline:

```css
.link-post .post-title .post-title-link {
  text-decoration: underline dotted;
  text-decoration-color: var(--color-text-muted);
  text-decoration-thickness: 0.05em;
  text-underline-offset: 0.2em;
}
```

To hide the arrow:

```css
.link-post .post-title-link::after {
  display: none;
}
```

See the [Custom CSS Guide](custom-css.md) for more.

## From other apps

- **API and front matter**: set `link_url`. See the [API guide](api.md).
- **Pagecord CLI**: use `--link-url`, or `link_url` in front matter. `--link-url ""` clears it. See [Pagecord CLI](pagecord-cli.md).
- **Obsidian**: add `link_url` to a note's frontmatter. See [Obsidian](obsidian.md).
- **Micropub**: send `bookmark-of`. See [Micropub](micropub.md).
