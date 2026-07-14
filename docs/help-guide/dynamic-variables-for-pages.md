---
title: "Dynamic Variables for Pages"
published: true
published_at: 2025-12-17T16:36:48+00:00
attachments:
  gallery-default:
    file: images/dynamic-variables/gallery-default.webp
    sgid: "eyJfcmFpbHMiOnsiZGF0YSI6ImdpZDovL3BhZ2Vjb3JkL0FjdGl2ZVN0b3JhZ2U6OkJsb2IvMjE1NjA_ZXhwaXJlc19pbiIsInB1ciI6ImF0dGFjaGFibGUifX0=--f75d5f20fc3b9e5d73d29d8a665b228d96990c38"
  gallery-title-below:
    file: images/dynamic-variables/gallery-title-below.webp
    sgid: "eyJfcmFpbHMiOnsiZGF0YSI6ImdpZDovL3BhZ2Vjb3JkL0FjdGl2ZVN0b3JhZ2U6OkJsb2IvMjE1NTg_ZXhwaXJlc19pbiIsInB1ciI6ImF0dGFjaGFibGUifX0=--338460c18413e4c94e4d4831c139ebd65b457be0"
  gallery-title-overlay:
    file: images/dynamic-variables/gallery-title-overlay.webp
    sgid: "eyJfcmFpbHMiOnsiZGF0YSI6ImdpZDovL3BhZ2Vjb3JkL0FjdGl2ZVN0b3JhZ2U6OkJsb2IvMjE1NTk_ZXhwaXJlc19pbiIsInB1ciI6ImF0dGFjaGFibGUifX0=--48190830675270a6240c192c85157b6be56a062c"
---

Pages in Pagecord support dynamic variables that let you automatically display lists of posts, tags, forms, and other content. These variables are processed when the page is rendered, so your content stays up-to-date without manual editing.

<div>
{{ table_of_contents | heading: "Table of Contents" }}
</div>

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

> **Important:** Paste variables directly into the page content, not inside a code block in the editor. Variables shown in code blocks here are examples only.

## Available Variables

### Posts

Display a list of your posts with dates and links. By default, posts are shown in the title layout, newest first, and longer lists lazy-load automatically as readers scroll.

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

Shows posts matching any of the tags.

```javascript
{{ posts | tag: photography, travel }}
```

#### **Filter by year**

```javascript
{{ posts | year: 2025 }}
```

#### **Filter by language**

Use `lang` to show posts in a particular language. Regional variants are normalised, so `pt-BR` matches posts marked as `pt`.

```javascript
{{ posts | lang: en }}
```

Posts that use your blog's default language setting are included when the filter matches the blog language.

#### **Sort order**

By default, posts are shown newest first. Use `sort: asc` to show oldest first – useful for chronological archives.

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

#### **Display as gallery**

Render posts as a grid of image thumbnails with automatic lazy-loading pagination. Each tile uses the post's Open Graph image, or the first image in the post body if no Open Graph image is set. Posts with no image are not shown.

```javascript
{{ posts | style: gallery }}
```

{{ attachment: gallery-default }}

Gallery titles are included in the HTML but hidden by default. You can show or overlay them with custom CSS – see [Posts gallery: customising the layout](https://help.pagecord.com/custom-css#posts-gallery-customising-the-layout).

#### **Style with filters**

You can combine `style` with any other filter parameter.

```javascript
{{ posts | style: card | tag: photography }}
```

```javascript
{{ posts | style: stream | year: 2026 | sort: asc }}
```

```javascript
{{ posts | style: stream | title: false }}
```

#### **Limit with filters**

You can combine `limit` with any other filter parameter.

```javascript
{{ posts | limit: 5 | tag: photography }}
```

```javascript
{{ posts | style: card | limit: 1 }}
```

### Posts by Year

Display posts grouped by year with headers – perfect for archive pages.

#### **Basic usage**

```javascript
{{ posts_by_year }}
```

#### **Filter by tag**

```javascript
{{ posts_by_year | tag: photography }}
```

#### **Filter by multiple tags**

Shows posts matching any of the tags.

```javascript
{{ posts_by_year | tag: photography, travel }}
```

#### **Exclude posts with a tag**

```javascript
{{ posts_by_year | without_tag: personal }}
```

#### **Exclude posts with multiple tags**

```javascript
{{ posts_by_year | without_tag: personal, draft }}
```

#### **Only posts with a title**

```javascript
{{ posts_by_year | title: true }}
```

#### **Only posts sent as newsletter**

```javascript
{{ posts_by_year | emailed: true }}
```

#### **Only posts not sent in a newsletter**

```javascript
{{ posts_by_year | emailed: false }}
```

#### **Filter by language**

Use `lang` to create language-specific archives.

```javascript
{{ posts_by_year | lang: en }}
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
{{ updated_at | format: datetime }}
```

Note: `long` and `long_datetime` always display month names in English. For non-English blogs, use the default or a numeric format.

You can style the output with the CSS class `updated-at`.

### Table of Contents

Build a linked table of contents from the headings in the page.

```javascript
{{ table_of_contents }}
```

The list includes headings from `h2` to `h6`, using nested numbering for deeper sections.

To show a heading without adding it to the table of contents, use the `heading` parameter:

```javascript
{{ table_of_contents | heading: "Table of contents" }}
```

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

_Paste it directly into the page content, not inside a code block in the editor._

## Examples

### Simple Archive Page

Create a page called "Archive" with this content:

```javascript
Here's everything I've written:

{{ posts_by_year }}
```

### Recent Posts on your Home Page

```javascript
My latest posts

{{ posts | limit: 5 }}
```

### One Featured Card

```javascript
Featured post

{{ posts | style: card | limit: 1 }}
```

### Microblog Stream

Show title-free posts as a full-content stream:

```javascript
Notes

{{ posts | style: stream | title: false }}
```

### Photo Gallery

Show only posts that have an image:

```javascript
Photos

{{ posts | style: gallery }}
```

{{ attachment: gallery-title-below }}

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
- If a variable isn't recognised, it will appear as-is in your content
- The posts list automatically excludes unpublished and scheduled posts
- Dynamic variables inside inline code or code blocks are left alone
- The table of contents variable uses headings in the page body
- Tags are sorted alphabetically
