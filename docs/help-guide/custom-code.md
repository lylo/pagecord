---
title: "Adding custom code"
published: true
---

Premium customers can add their own HTML (including `<script>`) to every page of their blog. This is useful for things like:

- adding support for third party analytics, such as Plausible or Fathom
- site verification tags for search engines
- identity links for verifying your blog on Mastodon, without showing a social icon in your navigation
- adding dynamic features like a copy button for code blocks, or article progress bars

Custom code needs an active subscription. Unlike custom CSS and the custom footer, it isn't available during the free trial.

To add custom code, head over to **Settings** → **Custom Code**.

> Note: Custom code is an advanced feature. Anything you add runs on every page of your blog, so a broken snippet can break your whole site. Customer support for writing or debugging custom code is not possible.


<div>
{{ table_of_contents | heading: "Table of Contents" }}
</div>

---

## Head code and body code

There are two different code blocks you can customise:

**Head Code** is added just before the closing `</head>` tag. Handy for third party analytics, `rel=me`, or for a verification tag.

**Body Code** is added just before the closing `</body>` tag. Use it for anything visible on the page, like a copy button for code blocks.

The surrounding HTML looks like this:

```html
<html>
  <head>
    ...
    <!-- Your head code gets inserted here -->
  </head>
  <body>
    <main>
      ...
    </main>
    <!-- Your body code gets inserted here -->
  </body>
</html>
```

If you only want to add a badge, a webring link or a line of text to the bottom of your blog, use [Custom footer](custom-footer.md) instead. It's simpler and safer.

## What's allowed in head code

Only the tags that belong in the head of a page:

`<script>`, `<style>`, `<link>`, `<meta>`, `<noscript>` and `<template>`

Pagecord checks your code before saving it. If you paste something else, you'll see:

> can only contain \<script>, \<style>, \<link>, \<meta>, \<noscript> and \<template> tags. Move \<div> to the body code instead

This usually happens when a snippet has both a script and a visible element. Put the script part in **Head code** and the rest in **Body code**.

Two tags belong in a head but still aren't accepted:

- `<title>`, because Pagecord sets your page titles for you. You can change them under Blog Settings.
- `<base>`, because it would rewrite every relative link on your blog.

Body code accepts any HTML. Each box holds up to 8KB.

## Switching it off

If your blog starts misbehaving after you add something, untick **Head and body code enabled**. Your code is kept, it just stops being added to your pages, which makes it easy to rule out as the cause. Custom CSS and your custom footer are not affected.

## What happens if I cancel?

Unlike custom CSS and the custom footer, custom code stops running when your subscription ends. Nothing is deleted, so if you subscribe again it starts working straight away.

## A first example

Here's a Plausible analytics tag, which goes in the **Head Code** box:

```html
<script defer data-domain="yourblog.pagecord.com" src="https://plausible.io/js/script.js"></script>
```

Replace `yourblog.pagecord.com` with your own blog address. If you use a custom domain, use that instead.

## Verifying your blog on Mastodon

Mastodon puts a green tick next to your website if it can find a `rel="me"` link on your blog pointing back at your profile. Pagecord adds one automatically for every social link in your navigation, so if you're happy to show a Mastodon icon there, you don't need custom code for this at all. See [SEO & Discovery](seo-and-discovery.md).

If you'd rather not have the icon, add the link yourself in **Head code**:

```html
<link rel="me" href="https://mastodon.social/@you">
```

Use your own profile URL, not your handle. Then add your blog's address to your Mastodon profile metadata and save it – verification is reciprocal, so both halves have to be in place. Mastodon only re-checks the link when you save your profile, so save it again even if nothing has changed.

The same trick works for anything else that verifies this way, such as Pixelfed.

## Writing your own scripts

If you're adding JavaScript that changes the page, there are a few things to know about Pagecord.

**Use `turbo:load`, not `DOMContentLoaded`.** Pagecord uses [Turbo](https://turbo.hotwired.dev/), so moving between pages doesn't reload the browser. `DOMContentLoaded` fires once and then never again, so your script would stop working as soon as a reader clicks a link.

**Listen for `turbo:frame-load` as well.** Your post list loads more posts as the reader scrolls, and `turbo:load` doesn't fire for those. Without this, your script runs on the first batch of posts and silently skips every one after it. Bind the same function to both events.

**Make your script safe to run twice.** Because both events fire more than once, check whether you've already added your element before adding it again.

**Register your listeners once.** Body code is re-run every time a reader moves to another page, so `document.addEventListener` inside it adds another listener each time. After ten pages you have ten copies of your script running, and anything that fetches from another service will do it ten times over. Set a flag on `window` and only register when it isn't there yet. Every recipe shows the pattern.

**Don't add anything inside a code block.** Pagecord highlights code after the page has loaded, and it does so by replacing everything inside each `<pre>` element. Anything you've put in there is destroyed, and any text it contained gets swallowed into the code itself. Add your element next to the `<pre>`, not inside it. The copy button recipe shows the pattern.

### Selectors you can use

Every page carries a `data-page-type` attribute on the `<body>` tag telling you which kind of page you're on:

| Selector | Page |
| --- | --- |
| `[data-page-type="post"]` | A single post |
| `[data-page-type="page"]` | A static page |
| `[data-page-type="home-page"]` | A custom home page |
| `[data-page-type="index"]` | The post list |

The same names appear as a class on the `.blog` container, so `.blog.post` works too. Use the container class for content, and the `<body>` attribute when you need to style the page itself, such as giving posts a different background.

The `<body>` tag also carries `data-theme`, so you can target a particular theme with something like `[data-theme="mint"]`.

For everything inside the page, the Blog Structure map in the [Custom CSS guide](custom-css.md) is the fullest picture of how a blog page is put together. The ones you'll reach for most often in a script are `article.post`, `.post-title`, `.post-body`, `.post-date`, `.tags-container` and `.tag`, and `.blog-footer` and `.custom-footer`. Post lists use `.post-stream-item`, `.post-row` or `.post-card`, depending on the layout you've chosen.

### Colours

Use your theme's colour variables rather than fixed colours, and your code will follow the reader's light or dark mode automatically. The most useful are `--color-text`, `--color-text-light`, `--color-accent`, `--color-bg`, `--color-bg-subtle` and `--color-border`.

## Ready-made recipes

The [Custom code recipes](custom-code-recipes.md) page has snippets you can paste straight in: a copy button for code blocks, a table of contents for posts, and webmentions.
