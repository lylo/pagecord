---
title: "Custom CSS"
published: true
---

Custom CSS is an advanced feature that gives you finer control over the look and feel of your blog. You can change fonts, colors, adjust spacing, hide elements and more.

### A Quick Note

Pagecord is small business. It's not possible to offer customer support with writing or debugging custom CSS — you're on your own with this one!

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
│ │ │ │ ┌──────────────────┐ ┌─────────────────────┐ │ │ │ │
│ │ │ │ │ .avatar-container│ │ .blog-title         │ │ │ │ │
│ │ │ │ │ [ .avatar ]      │ │                     │ │ │ │ │
│ │ │ │ └──────────────────┘ └─────────────────────┘ │ │ │ │
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
│ │ │ │ .lexxy-content (The post body text)           │ │ │ │
│ │ │ └──────────────────────────────────────────────┘ │ │ │
│ │ │ ┌──────────────────────────────────────────────┐ │ │ │
│ │ │ │ <footer> (Date, tags, and actions)           │ │ │ │
│ │ │ └──────────────────────────────────────────────┘ │ │ │
│ │ └──────────────────────────────────────────────────┘ │ │
│ │                                                      │ │
│ │ ┌──────────────────────────────────────────────────┐ │ │
│ │ │ .blog-footer (Pagecord branding)                 │ │ │
│ │ └──────────────────────────────────────────────────┘ │ │
│ └──────────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────┘
```

## Where to add the custom CSS

Head to `Settings > Appearance` and scroll to the "Custom CSS" section. Paste your CSS code into the text area provided and click Update.

## Examples

Here are some examples of CSS snippets you can use to customise your blog.

### Centering the Top Navigation

By default, the navigation links are aligned to the right. This will move them to the center.

```css
nav {
  justify-content: center;
}
```

### Changing the font

Pagecord has three lovely default fonts: Sans-Serif (Inter), Serif (Source Sans Pro), and Monospace (IBM Plex Mono). If you'd like to use a different font, you can import it from [Google Fonts](https://fonts.google.com/) or [Bunny Fonts](https://fonts.bunny.net/) (the only providers supported). Here's an example of using the "Lato" font from Google Fonts which is a solid alternative sans-serif choice:

```css
@import url('https://fonts.googleapis.com/css2?family=Lato:ital,wght@0,100;0,300;0,400;0,700;0,900;1,100;1,300;1,400;1,700;1,900&display=swap');

body {
  font-family: Lato, sans-serif;
}
```

### Change the size of the body font

While Pagecord defaults to industry-standard font sizes, you might prefer your fonts to be slightly larger. Try this:

```css
article {
  font-size: 1.2rem;
}
```

### Using a different font for headings

You might like sans-serif fonts for your body text and a serif font for headings. If your Pagecord font is set to Sans Serif, add this to switch headings to the default serif font:

```css
h1, h2, h3, h4, h5 {
  font-family: SourceSerif4Variable, serif;
}
```

### Stacking the Avatar and Title in the centre

If you want your avatar to appear above your blog title and both to be centered:

```css
.avatar-container {
  flex-direction: column;
  align-items: center;
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

### Centering the Bio

Center the bio text below the title:

```css
.bio {
  text-align: center;
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
  font-size: 0.75em
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

### Add text to the upvote button

You can add text next to the upvote icon like this:

```css
.upvote::after {
  content: "Like";
  margin-inline-start: 0.25em;
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

### Adding a background image to your blog

You can set a background image so that it fits the viewport and scales nicely. It can be unreliable to rely on a 3rd party URL for the image, so I would recommend creating page on your Pagecord blog and upload your background image of choice to it. View the page, then copy the link to the image and then reference that image in your CSS.


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
  opacity: 0.9;
}
```
