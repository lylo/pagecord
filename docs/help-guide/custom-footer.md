---
title: "Adding a custom footer"
published: true
---

Premium customers can add an HTML snippet to the footer of their blog. This is useful for things like:

- badge buttons
- webring links
- links to other sites or projects
- a short line of text, like a copyright notice

To add your own custom HTML, head over to **Settings** → **Appearance** → **Custom footer**

### A Quick Note

Custom footer is intended for small, simple snippets. Pagecord checks that the HTML is safe before saving it, but customer support for writing or debugging custom HTML and CSS is limited.

## What HTML is supported?

Only basic HTML is supported, such as links, text formatting, paragraphs and images.

Scripts, embeds, forms, iframes, inline styles, and unsafe attributes are not supported.

Examples:

```html
<p>
  <a href="https://example.com">My other site</a>
</p>
```

Or

```html
<a href="https://example.com">
  <img src="https://example.com/badge.gif" alt="My badge">
</a>
```

You can use full URLs or local paths. For example, `/about` will link to a page on your own blog.

## Finding badge buttons

If you like old-school web buttons, [88x31db](https://88x31db.com) has an extensive collection.

If you use an image from another site, ensure you have permission to use it and that the image URL is reliable. Hosting images yourself is better.

## Styling your footer

Pagecord keeps the custom footer styling deliberately minimal. Content is centred and images are kept within the page width, but all other styling is left up to you.

For example, if you'd like footer links to match the style used in posts, you will need to add this to **Settings** → **Appearance** → **Custom CSS**:

```css
.custom-footer a {
  color: var(--color-accent);
  text-decoration: underline;
  font-weight: 500;
}

.custom-footer a:hover {
  color: var(--color-accent-hover);
}
```

You can target `.custom-footer` in Custom CSS for any other styling you want to add for additional elements.
