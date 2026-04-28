---
title: "Dynamic Variables for Pages"
published: true
published_at: 2025-12-17T16:36:48+00:00
---

Pages in Pagecord support dynamic variables that let you automatically display lists of posts, tags, and other content. These variables are processed when the page is rendered, so your content stays up-to-date without manual editing.

## Basic Syntax

Dynamic variables use double curly braces:

```javascript
{{ variable_name }}
```

You can add parameters using a colon:

```javascript
{{ variable_name | param: value }}
```

Multiple parameters are separated by pipes:

```javascript
{{ variable_name | param1: value1 | param2: value2 }}
```

## Available Variables

### Posts

Display a list of your posts with dates and links.

#### **Basic usage**

```javascript
{{ posts }}
```

#### **With a limit**

Use `limit` to show a fixed number of posts. When a limit is set, posts are not lazy-loaded or paginated.

```javascript
{{ posts | limit: 10 }}
```

#### **Filter by tag**

```javascript
{{ posts | tag: photography }}
```

#### **Filter by multiple tags**

Shows posts matching any of the tags

```javascript
{{ posts | tag: photography, travel }}
```

#### **Filter by year**

```javascript
{{ posts | year: 2025 }}
```

#### **Sort order**

By default, posts are shown newest first. Use `sort: asc` to show oldest first — useful for chronological archives.

```javascript
{{ posts | sort: asc }}
```

#### **Exclude posts with a tag**

```javascript
{{ posts | without_tag: personal }}
```

#### **Exclude posts with multiple tags**

```javascript
{{ posts | without_tag: personal, draft }}
```

#### **Only posts with a title**

```javascript
{{ posts | title: true }}
```

#### **Only posts without a title**

```javascript
{{ posts | title: false }}
```

#### **Only posts sent in a newsletter**

```javascript
{{ posts | emailed: true }}
```

#### **Only posts not sent in a newsletter**

```javascript
{{ posts | emailed: false }}
```

#### **Display as cards**

Render posts as cards (the same layout as the "cards" blog style) with automatic lazy-loading pagination.

```javascript
{{ posts | style: card }}
```

#### **Display as stream**

Render posts as a full-content stream (the same layout as the "stream" blog style) with automatic lazy-loading pagination.

```javascript
{{ posts | style: stream }}
```

#### **Display as title**

Render posts as a date-and-title list (the same layout as the "title" blog style) with automatic lazy-loading pagination. This is the default when no style or limit is specified.

```javascript
{{ posts | style: title }}
```

#### **Style with filters**

You can combine `style` with any other filter parameter.

```javascript
{{ posts | style: card | tag: photography }}
```

#### **Limit with filters**

You can combine `limit` with any other filter parameter.

```javascript
{{ posts | limit: 5 | tag: photography }}
```

### Posts by Year

Display posts grouped by year with headers — perfect for archive pages.

#### **Basic usage**

```javascript
{{ posts_by_year }}
```

#### **Filter by tag**

```javascript
{{ posts_by_year | tag: photography }}
```

#### **Exclude posts with a tag**

```javascript
{{ posts_by_year | without_tag: personal }}
```

#### **Only posts with a title**

```javascript
{{ posts_by_year | title: true }}
```

#### **Only posts sent as newsletter**

```javascript
{{ posts_by_year | emailed: true }}
```

#### **Sort order**

Show years in chronological order (oldest first) instead of the default newest first.

```javascript
{{ posts_by_year | sort: asc }}
```

### Tags

Display a list of all tags used in your posts.

#### **As a bullet list**

```javascript
{{ tags }}
```

#### **Inline (comma-separated)**

```javascript
{{ tags | style: inline }}
```

### Last Updated Date

Display the date the page was last updated. This is handy for pages that evolve over time, such as a Now page or a reading log.

```javascript
{{ updated_at }}
```

By default, the date is shown in your blog's locale format. Use the `format` parameter for a specific style:

| Format | Example |
|--------|---------|
| _(default)_ | 12 Sep 2026 _(locale-specific)_ |
| `datetime` | 12 Sep 2026 14:30 _(locale-specific + time)_ |
| `long` | 12 September 2026 _(English only)_ |
| `long_datetime` | 12 September 2026 14:30 _(English only)_ |
| `dd_mm_yyyy` | 12/09/2026 |
| `mm_dd_yyyy` | 09/12/2026 |
| `yyyy_mm_dd` | 2026-09-12 |

```javascript
{{ updated_at format: datetime }}
```

Note: `long` and `long_datetime` always display month names in English. For non-English blogs, use the default or a numeric format.

You can style the output with the CSS class `updated-at`.

### Email Subscription

Embed an email subscription form for readers to subscribe to your blog (premium customers only).

```javascript
{{ email_subscription }}
```

_Note: This only appears if you have email subscriptions enabled in your blog settings._

### Contact Form

Embed a contact form so readers can send you a message directly from your blog.

```javascript
{{ contact_form }}
```

_Note: This is a premium feature and only appears for subscribers and users on a free trial._

## Examples

### Simple Archive Page

Create a page called "Archive" with this content:

```javascript
Here's everything I've written:

{{ posts_by_year }}
```

### Recent Posts on your Home Page

```javascript
My latest Posts

{{ posts | limit: 5 }}
```

## Topic Index

```javascript
My Photography Posts

{{ posts | tag: photography }}

My Travel Posts

{{ posts | tag: travel }}

Browse posts by topic:

{{ tags }}
```

## Tips

- Dynamic variables only work in **pages**, not blog posts
- If a variable isn't recognized, it will appear as-is in your content
- The posts list automatically excludes unpublished and scheduled posts
- Tags are sorted alphabetically
