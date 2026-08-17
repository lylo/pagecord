---
title: "Using Custom CSS for advanced customisation"
published: true
attachments:
  gallery-title-below:
    file: images/dynamic-variables/gallery-title-below.webp
    sgid: "eyJfcmFpbHMiOnsiZGF0YSI6ImdpZDovL3BhZ2Vjb3JkL0FjdGl2ZVN0b3JhZ2U6OkJsb2IvMjE1NTg_ZXhwaXJlc19pbiIsInB1ciI6ImF0dGFjaGFibGUifX0=--338460c18413e4c94e4d4831c139ebd65b457be0"
  gallery-title-overlay:
    file: images/dynamic-variables/gallery-title-overlay.webp
    sgid: "eyJfcmFpbHMiOnsiZGF0YSI6ImdpZDovL3BhZ2Vjb3JkL0FjdGl2ZVN0b3JhZ2U6OkJsb2IvMjE1NTk_ZXhwaXJlc19pbiIsInB1ciI6ImF0dGFjaGFibGUifX0=--48190830675270a6240c192c85157b6be56a062c"
---

Custom CSS is an advanced feature that gives you finer control over the look and feel of your blog. You can change fonts, colours, adjust spacing, hide elements and more.

**New to Custom CSS?** Try the [Theme Garden](https://pagecord.com/app/settings/theme_garden) first – it has curated CSS templates you can preview and apply with one click, no coding required.

<div>
{{ table_of_contents | heading: "Table of Contents" }}
</div>

### A Quick Note

Pagecord is a small business. It's not possible to offer customer support with writing or debugging custom CSS – you're on your own with this one!

If you're new to CSS, check out the [MDN CSS First Steps guide](https://developer.mozilla.org/en-US/docs/Learn/CSS/First_steps).

---

## Blog Structure

To help you know which elements to target, here is a visual map of the blog page structure:

```text
┌──────────────────────────────────────────────────────────┐
│ body (Main background and global font)                   │
│ ┌──────────────────────────────────────────────────────┐ │
│ │ .blog                                                │ │
│ │ ┌──────────────────────────────────────────────────┐ │ │
│ │ │ <header>                                         │ │ │
│ │ │ ┌──────────────────────────────────────────────┐ │ │ │
│ │ │ │ <nav> (Links and social icons)               │ │ │ │
│ │ │ └──────────────────────────────────────────────┘ │ │ │
│ │ │ ┌──────────────────────────────────────────────┐ │ │ │
│ │ │ │ .titlebar                                    │ │ │ │
│ │ │ │ ┌──────────────────────────────────────────┐ │ │ │ │
│ │ │ │ │ .avatar-container (when avatar present)  │ │ │ │ │
│ │ │ │ │ [ .avatar ] [ .blog-title ]              │ │ │ │ │
│ │ │ │ └──────────────────────────────────────────┘ │ │ │ │
│ │ │ └──────────────────────────────────────────────┘ │ │ │
│ │ │ ┌──────────────────────────────────────────────┐ │ │ │
│ │ │ │ .bio (Your profile description)              │ │ │ │
│ │ │ └──────────────────────────────────────────────┘ │ │ │
│ │ │ ─────────────────── <hr> ──────────────────────  │ │ │
│ │ └──────────────────────────────────────────────────┘ │ │
│ │                                                      │ │
│ │ ┌──────────────────────────────────────────────────┐ │ │
│ │ │ <article class="post">                           │ │ │
│ │ │ ┌──────────────────────────────────────────────┐ │ │ │
│ │ │ │ .post-title                                  │ │ │ │
│ │ │ └──────────────────────────────────────────────┘ │ │ │
│ │ │ ┌──────────────────────────────────────────────┐ │ │ │
│ │ │ │ .post-body (The post body text)              │ │ │ │
│ │ │ └──────────────────────────────────────────────┘ │ │ │
│ │ │ ┌──────────────────────────────────────────────┐ │ │ │
│ │ │ │ <footer> (Date, tags, and actions)           │ │ │ │
│ │ │ └──────────────────────────────────────────────┘ │ │ │
│ │ └──────────────────────────────────────────────────┘ │ │
│ │                                                      │ │
│ │ ┌──────────────────────────────────────────────────┐ │ │
│ │ │ .comments (Loaded when a reader opens them)      │ │ │
│ │ │ ┌──────────────────────────────────────────────┐ │ │ │
│ │ │ │ .comment-form                                │ │ │ │
│ │ │ └──────────────────────────────────────────────┘ │ │ │
│ │ │ ┌──────────────────────────────────────────────┐ │ │ │
│ │ │ │ .comment-list (One .comment per comment)     │ │ │ │
│ │ │ └──────────────────────────────────────────────┘ │ │ │
│ │ └──────────────────────────────────────────────────┘ │ │
│ │                                                      │ │
│ │ ┌──────────────────────────────────────────────────┐ │ │
│ │ │ .blog-footer (Custom footer and Pagecord logo)   │ │ │
│ │ └──────────────────────────────────────────────────┘ │ │
│ └──────────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────┘
```

## Where to add the custom CSS

Head to `Settings > Custom Code` and find the "Custom CSS" section. Paste your CSS code into the text area provided and click **Save custom CSS**.

Writing your own custom CSS is a premium feature. Your CSS is inserted into the `<head>` of your blog pages, and once it's saved it keeps rendering whatever plan you're on.

For safety, Pagecord validates custom CSS before saving it:

- The maximum size is 16KB
- `@import` is only allowed for HTTPS URLs from Google Fonts and Bunny Fonts
- CSS custom properties, logical properties, `@supports`, and `@layer` are supported
- Unsafe content, invalid import URLs, and unsupported syntax such as nested CSS are rejected

## Examples

Here are some examples of CSS snippets you can use to customise your blog.

### Changing the font

Pagecord has three lovely default fonts: Sans-Serif (Inter), Serif (Lora), and Monospace (IBM Plex Mono). If you'd like to use a different font, you can import it from [Google Fonts](https://fonts.google.com/) or [Bunny Fonts](https://fonts.bunny.net/) (the only providers supported). Here's an example of using the "Lato" font from Google Fonts which is a solid alternative sans-serif choice:

```css
@import url("https://fonts.googleapis.com/css2?family=Lato:ital,wght@0,100;0,300;0,400;0,700;0,900;1,100;1,300;1,400;1,700;1,900&display=swap");

body {
  font-family: Lato, sans-serif;
}
```

### Change the size of your blog text

Pagecord uses your browser's normal text size by default, which is usually 16px. If you'd like your whole blog to feel slightly larger, adjust Pagecord's base font size:

```css
:root {
  --font-size-base: 112.5%;
}
```

That makes the default text size 18px for readers whose browser default is 16px, while still respecting readers who have changed their browser's text size.

If your text only feels a little small on mobile, you can make a smaller adjustment just for narrow screens:

```css
@media (max-width: 640px) {
  :root {
    --font-size-base: 106.25%;
  }
}
```

If you only want to change posts and pages, you can target `article`:

```css
article {
  font-size: 1.125em;
}
```

If you want to change only the authored post or page body, target `.post-body` instead:

```css
.post-body {
  font-size: 1.125em;
}
```

### Using a different font for headings

You might like sans-serif fonts for your body text and a serif font for headings. If your Pagecord font is set to Sans Serif, add this to switch headings to the default serif font:

```css
h1, h2, h3, h4, h5 {
  font-family: "Lora Variable", serif;
}
```

### Centering the Header

Center the navigation, title, avatar, and bio:

```css
nav {
  justify-content: center;
}

.titlebar, .avatar-container {
  flex-direction: column;
  align-items: center;
}

.bio {
  text-align: center;
}
```

This targets both `.titlebar` and `.avatar-container` so it works whether or not you have an avatar.

Or pick and choose from the individual options below.

### Centering the Top Navigation

By default, the navigation links are aligned to the right. This will move them to the center.

```css
nav {
  justify-content: center;
}
```

### Centering the Title and Avatar

If you have an avatar, target `.avatar-container` to stack and center both:

```css
.avatar-container {
  flex-direction: column;
  align-items: center;
}
```

If you don't have an avatar (or want it to work either way), include `.titlebar` too:

```css
.titlebar, .avatar-container {
  flex-direction: column;
  align-items: center;
}
```

### Centering the Bio

Center the bio text below the title:

```css
.bio {
  text-align: center;
}
```

### Hiding the Avatar

If you have an avatar uploaded but want to hide it from your blog header (it will still be used for the favicon):

```css
.avatar {
  display: none;
}
```

### Make the title less prominent, and style it using all caps

```css
.blog-title {
  font-weight: 200;
  text-transform: uppercase;
}
```

### Change the border at the bottom of the header

By default the border is just a straight line. You can use CSS to create a more embellished divider. Here's an example that [Olly uses on his blog](https://olly.world):

```css
header hr {
  border: none;
  text-align: center;
  background: linear-gradient(var(--color-border), var(--color-border)) center / 40% 1px no-repeat;
  margin: 2rem 0;
}

header hr::before {
  content: "☆";
  color: var(--color-text-muted);
  background: var(--color-bg);
  padding: 0 0.5em;
  font-size: 0.75em;
}
```

### Reordering the header elements

By default, the navigation appears above the title. You can use CSS `order` to rearrange the header elements, for example to show the title first:

```css
/* set the header to use flexbox layout and stack items vertically */
header {
  display: flex;
  flex-direction: column;
}

header > nav {
  order: 2;
}

header > .titlebar {
  order: 1;
}

header > .bio {
  order: 3;
}

header > .email-subscriber-form {
  order: 4;
}

header > hr {
  order: 5;
}
```

### Add text to the reply by email button

You can add text next to the reply by email icon like this:

```css
.reply-by-email::after {
  content: "Reply";
  margin-inline-start: 0.25em;
}
```

Or remove the icon entirely and just have text:

```css
.reply-by-email::before {
  content: "Reply";
}

a.reply-by-email .icon {
  display: none;
}
```

### Add text to the upvote button

You can add text next to the upvote icon like this:

```css
.upvote::after {
  content: "Like";
  margin-inline-start: 0.25em;
}
```

### Make the upvote heart solid

The upvote heart is drawn as an outline, and fills in red once a reader likes the post. If you'd rather it was solid from the start:

```css
.upvote-heart {
  fill: currentColor;
  stroke: none;
}
```

### Stack the post footer items on different lines

If you prefer the post footer items (date, tags, actions) to be stacked vertically instead of side-by-side, use this CSS:

```css
article footer {
  flex-direction: column;
  align-items: flex-start;
  gap: 0.25rem;
}

article footer .post-actions {
  flex-direction: column;
  align-items: flex-start;
  gap: 0.25rem;
}
```

### Styling comments

Comments are loaded on demand, so until a reader opens them the page source contains nothing but an empty placeholder. To see the markup, open a post, click the comment icon, then right-click a comment and choose "Inspect" – developer tools show the live page rather than the original source.

The structure looks like this:

```text
.comments                  The whole section
  .comments-heading        The "Comments" heading
  .comment-form            The box for leaving a comment
  .comment-notice          "Awaiting approval" and "comments closed" messages
  .comment-list
    .comment               One comment
      .comment-meta        The name, badge and date row
        .comment-name
        .comment-badge     The "Author" label on your own comments
        .comment-date
      .comment-message     The comment text
      .comment-replies     Nested replies, each also a .comment
    .comments-more         The "load more comments" link
```

In the post footer, `.comment-link` is the button showing the icon (wrapped in a small form with the class `.comment-link-form`) and `.comment-count` is the number beside it. Style it with the bare class rather than an element selector like `a.comment-link`.

Comments you leave on your own posts also get a `.comment-by-author` class, which tints them with your theme's accent colour. To turn that off:

```css
.comment-by-author {
  background: none;
  border-inline-start: none;
  padding: 0;
}
```

The space between comments sits on the gap between them rather than on `.comment` itself, and a second rule covers the comments that arrive when a reader clicks "load more". Change both together so every page of comments is spaced the same:

```css
.comment + .comment,
turbo-frame > .comment:first-child {
  margin-block-start: 1.75rem;
}
```

The section is set slightly smaller than your body text, and everything inside is sized relative to that. To opt out:

```css
.comments {
  font-size: 1rem;
}
```

### Styling posts by tag

Posts with tags include a `data-tags` attribute on their wrapper element. You can use this to style posts differently based on their tags:

```css
[data-tags~="photo"] {
  border-left: 3px solid #f4a435;
}
```

### Non-italic blockquotes

Blockquotes are styled in italics by default. If you prefer upright text, use this snippet. The second rule ensures that any emphasised text inside the quote still appears italic:

```css
blockquote {
  font-style: normal;
}
blockquote em {
  font-style: italic;
}
```

### Full-width images

By default, images display at their natural size. To make all images stretch to fill the full width of your posts:

```css
article img {
  width: 100%;
  height: auto;
  max-block-size: none;
}
```

### Left-align images

Images are centered by default. To left-align them instead:

```css
article img {
  margin-inline-start: 0;
}
```

### Galleries: fewer columns on mobile

By default, image galleries render in 2 or 3 columns depending on how many images you've added. On narrow screens this can feel cramped. Change the layout below a chosen breakpoint.

**One image per row on mobile:**

```css
@media (max-width: 600px) {
  .attachment-gallery {
    grid-template-columns: 1fr;
  }
}
```

**Two images per row on mobile:**

```css
@media (max-width: 600px) {
  .attachment-gallery {
    grid-template-columns: repeat(2, 1fr);
  }
}
```

Adjust `600px` to your preferred breakpoint.

### PDF attachments: changing the layout

A PDF attachment renders its first page as a thumbnail, with a download link and the file size below. You can target the following classes:

- `.attachment--pdf` – the container
- `.attachment__page` – the rendered first page
- `.attachment__caption` – the line beneath it
- `.attachment__title` – the caption you typed in the editor, if any
- `.attachment__link` – the download link
- `.attachment__size` – the file size

**Show it as a compact row** instead of a full-size page:

```css
.attachment--pdf {
  display: flex;
  align-items: center;
  gap: 1rem;
}

.attachment--pdf .attachment__page { max-block-size: 6rem; }
.attachment--pdf .attachment__caption { justify-content: flex-start; }
```

**Change how large the page appears:**

```css
.attachment--pdf .attachment__page { max-block-size: 300px; }
```

**Hide the file size:**

```css
.attachment--pdf .attachment__size { display: none; }
```

The separator dots are attached to the items either side of the download link, so hiding an item hides its dot too. The one exception is hiding the download link itself, which needs an extra line:

```css
.attachment--pdf .attachment__link { display: none; }
.attachment--pdf .attachment__size::before { content: none; }
```

### Posts gallery: customising the layout

The `{{ posts | style: gallery }}` dynamic variable renders posts as a grid of square thumbnails. You can target the following classes:

- `.posts-gallery` – the grid container
- `.posts-gallery-item` – each tile (an `<a>` linking to the post)
- `.posts-gallery-image` – the wrapper around the thumbnail
- `.posts-gallery-title` – the post title (hidden by default)

**Change the number of columns:**

```css
.posts-gallery { grid-template-columns: 1fr; }
@media (min-width: 600px) { .posts-gallery { grid-template-columns: repeat(2, 1fr); } }
@media (min-width: 900px) { .posts-gallery { grid-template-columns: repeat(4, 1fr); } }
```

**Use the natural aspect ratio of each image** (instead of square crops):

```css
.posts-gallery-image { aspect-ratio: auto; }
.posts-gallery-image img { height: auto; }
```

**Show the post title under each tile:**

```css
.posts-gallery-title {
  display: block;
  margin-top: 0.25rem;
  font-size: 0.875rem;
}
```

{{ attachment: gallery-title-below }}

**Show the post title inside the image:**

```css
.posts-gallery-item {
  position: relative;
  display: block;
}

.posts-gallery-title {
  position: absolute;
  inset-inline: 0;
  inset-block-end: 0;
  display: block;
  padding: 1.5rem 0.75rem 0.75rem;
  color: white;
  background: linear-gradient(to top, rgb(0 0 0 / 0.55), transparent);
}
```

This keeps the label background transparent at the top while adding contrast behind the text. If the title is still hard to read on pale images, add a subtle shadow:

```css
.posts-gallery-title {
  text-shadow: 0 1px 3px rgb(0 0 0 / 0.7);
}
```

{{ attachment: gallery-title-overlay }}

### Adding a background image to your blog

You can set a background image so that it fits the viewport and scales nicely. It can be unreliable to rely on a 3rd party URL for the image, so I would recommend creating a page on your Pagecord blog and uploading your background image there. View the page, copy the image URL, then reference that image in your CSS.


```css
body {
  background-image: url("https://images.unsplash.com/photo-1465146344425-f00d5f5c8f07?ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&q=80&w=2076");
  background-size: cover;
  background-position: center;
  background-repeat: no-repeat;
  background-attachment: fixed;
  min-height: 100vh;
}
```

To make the blog look nice with a background image, you'll need to add some padding and margin to the `.blog` container. I'd also recommend a `border-radius` too for curved corners, but that's optional:

```css
.blog {
  margin: 2rem auto;
  padding: 1rem 2rem;
  border-radius: 1rem;
}
```

Another nice touch is to make the blog background slightly transparent to allow the background image to show through:

```css
.blog {
  background-color: rgb(255 255 255 / 0.9);
}
```

Using `opacity` on `.blog` would also make your text and images transparent, so prefer setting a translucent background colour instead.
