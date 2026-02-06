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

```js
{{ posts }}
```

#### **With a limit**

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

#### **Combine parameters**

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

### Email Subscription

Embed an email subscription form for readers to subscribe to your blog (premium customers only).

```javascript
{{ email_subscription }}
```

_Note: This only appears if you have email subscriptions enabled in your blog settings._

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

- Dynamic variables only work in **pages** , not blog posts
- If a variable isn't recognized, it will appear as-is in your content
- The posts list automatically excludes unpublished and scheduled posts
- Tags are sorted alphabetically

