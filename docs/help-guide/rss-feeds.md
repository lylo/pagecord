---
title: "RSS feeds"
published: true
published_at: 2025-12-18T16:55:55+00:00
---

Every Pagecord blog has an RSS feed that readers can subscribe to using their favourite RSS reader.

## Your feed URL

Your RSS feed is available at:

```javascript
https://yourusername.pagecord.com/feed.xml
```

If you're using a custom domain:

```javascript
https://yourdomain.com/feed.xml
```

## Filtered feeds

You can filter your RSS feed by tag or language using query parameters. This is useful for readers who only want to follow specific topics or languages on your blog.

### Filter by tag

```javascript
https://yourusername.pagecord.com/feed.xml?tag=ruby
```

You can filter by multiple tags (posts matching any of the tags will be included):

```javascript
https://yourusername.pagecord.com/feed.xml?tag=ruby,rails
```

### Filter by language

```javascript
https://yourusername.pagecord.com/feed.xml?lang=es
```

Supported language codes: `en`, `es`, `fr`, `de`, `pt`.

### Combining filters

Filters can be combined:

```javascript
https://yourusername.pagecord.com/feed.xml?tag=ruby&lang=en
```

## Following Pagecord blogs

To follow a Pagecord blog, add the feed URL to an RSS reader.

Check out [Feedgrab](https://feedgrab.net), a free RSS reader from the create of Pagecord! ✨

