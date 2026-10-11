---
title: "Setting up navigation"
published: true
published_at: 2025-12-18T16:15:50+00:00
---

Add links to your blog's header so readers can find their way around.

## Adding navigation items

1. Go to **Settings** → **Navigation**
2. Choose the type of link you want to add
3. Fill in the details
4. Click **Add to Navigation**

## Types of navigation items

### Link to a page

Links to one of your published pages. The label is automatically set to the page title.

### Your posts

Links to the list of all your posts. It's labelled "Blog" by default, but you can change that to whatever suits your blog. You can only add one.

This is useful when you've set a page as your home page, since your posts then live at `/posts` rather than at the root of your blog.

### Custom link

A manual link with your own label and URL. Use this for:

- External links (e.g., your portfolio or shop)
- Any URL you want

You can use relative paths (like `/archive`) or full URLs (like `https://example.com`).

#### Adding a custom icon

A custom link can show an icon, either beside its label or instead of it. Icons are added as SVG code, the format most icon sites offer for copying.

1. Find an icon. [Simple Icons](https://simpleicons.org) has logos for thousands of brands, and [Phosphor](https://phosphoricons.com) has everyday symbols like headphones, a camera or a book.
2. Copy its SVG code.
3. Tick **Show a custom icon** and paste the code into the box.
4. Choose **Icon and label** to show both, or **Icon only** to show just the icon.

You don't need to worry about the icon's size or colour. Pagecord sizes it for your navigation and colours it to match your theme.

Icons must be simple: a single shape, up to 4 KB of SVG. Every Phosphor icon fits apart from the Duotone style, and so does almost every Simple Icons logo. If an icon is turned down, try a different style or a different icon.

With **Icon only**, screen readers still read out the label, so keep it descriptive.

To make an icon bigger or smaller, add some [custom CSS](custom-css.md) that targets the link by its URL:

```css
nav a[href="https://letterboxd.com/you"] svg {
  width: 1.25rem;
  height: 1.25rem;
}
```

Only use icons you have the right to use. Icons from Simple Icons and Phosphor are free to use, though brand logos still belong to their owners.

### Social link

Adds a social media icon to your header. Choose from:

- Apple Music
- Bluesky
- Email
- Facebook
- Foto
- GitHub
- Glass
- Hipstamatic
- Instagram
- LinkedIn
- Mastodon
- Pixelfed
- Reddit
- RSS
- Spotify
- Threads
- TikTok
- Web
- X
- YouTube

Enter the URL to your profile, or an email address for Email links, and the appropriate icon will be displayed. For anything not on this list, use a custom link with an icon.

### Search

Adds a search icon that links to your blog's [search page](blog-search.md), so readers can find your posts and pages. You can only add one.

You can also embed a search box in a page with the `{{ search }}` dynamic variable, instead of or as well as the navigation icon. See [Search](blog-search.md).

## Reordering navigation items

Drag items to change their order. The order you see in settings is the order they'll appear on your blog.

## Removing navigation items

Click the trash icon next to any navigation item to remove it.
