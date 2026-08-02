---
title: "Adding custom code"
published: true
---

Subscribers can add their own HTML to every page of their blog. This is useful for things like:

- third party analytics, such as Plausible or Fathom
- site verification tags for search engines
- loading a font from an external service
- chat widgets and embedded forms

To add custom code, head over to **Settings** → **Custom Code**.

Before you reach for this, it's worth knowing that Pagecord already includes [privacy-friendly analytics](analytics.md) for your blog, so you may not need anything extra.

### A Quick Note

Custom code is an advanced feature. Anything you add runs on every page of your blog, so a broken snippet can break your whole site. Customer support for writing or debugging custom code is not possible, so you're on your own with this one.

## Head code and body code

There are two boxes, and which one you use depends on the snippet.

**Head code** is added just before the closing `</head>` tag. Use it for analytics, verification meta tags, and fonts.

**Body code** is added just before the closing `</body>` tag. Use it for anything visible on the page, like chat widgets and embedded forms.

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

## An example

Here's a Plausible analytics tag, which goes in the **Head code** box:

```html
<script defer data-domain="yourblog.pagecord.com" src="https://plausible.io/js/script.js"></script>
```

Replace `yourblog.pagecord.com` with your own blog address. If you use a custom domain, use that instead.

## Writing your own scripts

If you're adding JavaScript that changes the page, there are two things to know about Pagecord.

**Use `turbo:load`, not `DOMContentLoaded`.** Pagecord uses Turbo, so moving between pages doesn't reload the browser. `DOMContentLoaded` fires once and then never again, so your script would stop working as soon as a reader clicks a link.

**Make your script safe to run twice.** Because `turbo:load` fires on every page, check whether you've already added your element before adding it again.

### Selectors you can use

Every page carries a `data-page-type` attribute on the `<body>` tag telling you which kind of page you're on:

| Selector | Page |
| --- | --- |
| `[data-page-type="post"]` | A single post |
| `[data-page-type="page"]` | A static page |
| `[data-page-type="home-page"]` | A custom home page |
| `[data-page-type="index"]` | The post list |

The same names appear as a class on the `.blog` container, so `.blog.post` works too. Use the container class for content, and the `<body>` attribute when you need to style the page itself, such as giving posts a different background.

The `<body>` tag also carries `data-theme`, so you can style for a particular theme with something like `[data-theme="mint"]`.

Inside a post you can target:

| Selector | Element |
| --- | --- |
| `article.post` | The whole post |
| `.post-title` | The post title |
| `.post-body` | The post content |
| `.post-date` | The date link in the post footer |
| `.tags-container`, `.tag` | Tags |
| `.blog-footer`, `.custom-footer` | The footer |

Post lists use `.post-stream-item`, `.post-row` or `.post-card`, depending on the layout you've chosen.

### Colours

Use your theme's colour variables rather than fixed colours, and your code will follow the reader's light or dark mode automatically. The most useful are `--color-text`, `--color-text-light`, `--color-accent`, `--color-bg`, `--color-bg-subtle` and `--color-border`.

### Example: showing webmentions

[Webmentions](https://indieweb.org/Webmention) let other sites tell you when they've linked to your post. Pagecord already marks your posts up with microformats, so this is a natural fit. There are three steps.

**1. Sign up at [webmention.io](https://webmention.io).** It signs you in using your own blog address, which needs a `rel="me"` link pointing at somewhere it can verify you, like GitHub. Pagecord adds one automatically for every social link in your navigation apart from RSS and Web, so adding a GitHub link in **Settings** → **Navigation** is enough.

**2. Advertise your endpoints.** This goes in **Head code**:

```html
<link rel="webmention" href="https://webmention.io/yourblog.pagecord.com/webmention">
<link rel="pingback" href="https://webmention.io/yourblog.pagecord.com/xmlrpc">
```

Replace `yourblog.pagecord.com` with your own blog address, and use your custom domain if you have one.

**3. Show them on your posts.** webmention.io only collects mentions, so nothing appears on your blog until you ask for them. This goes in **Body code**:

```html
<script>
  document.addEventListener("turbo:load", function () {
    if (document.body.dataset.pageType !== "post") return;
    if (document.querySelector(".webmentions")) return;

    const footer = document.querySelector("article footer");
    if (!footer || footer.dataset.webmentions) return;
    footer.dataset.webmentions = "loading";

    const target = document.querySelector("link[rel=canonical]")?.href || location.href;

    fetch("https://webmention.io/api/mentions.jf2?per-page=50&target=" + encodeURIComponent(target))
      .then(function (response) { return response.ok ? response.json() : null; })
      .then(function (feed) {
        const mentions = (feed && feed.children) || [];
        if (!mentions.length) return;

        const list = document.createElement("p");
        list.className = "webmentions";
        list.style.cssText = "margin-top:1.5rem;font-size:0.875em;color:var(--color-text-light)";
        list.append(mentions.length === 1 ? "1 mention from around the web: " : mentions.length + " mentions from around the web: ");

        mentions.forEach(function (mention, index) {
          const link = document.createElement("a");
          link.href = mention.url;
          link.rel = "nofollow ugc";
          link.textContent = (mention.author && mention.author.name) || new URL(mention.url).hostname;
          list.append(link);
          if (index < mentions.length - 1) list.append(", ");
        });

        footer.append(list);
      })
      .catch(function () {});
  });
</script>
```

It asks for the canonical address of the post, which is what other sites link to, and adds nothing at all when there are no mentions yet. Some mentions arrive without an author name, so those fall back to the name of the site they came from.

### Example: a copy button for code blocks

Adds a Copy button to the corner of every code block, which is handy if you write posts containing code. This goes in **Body code**:

```html
<script>
  document.addEventListener("turbo:load", function () {
    document.querySelectorAll(".post-body pre").forEach(function (block) {
      if (block.querySelector(".copy-code")) return;

      const code = block.innerText;

      const button = document.createElement("button");
      button.className = "copy-code";
      button.textContent = "Copy";
      button.style.cssText = "position:absolute;top:0.5rem;right:0.5rem;cursor:pointer;" +
        "font-size:0.75rem;padding:0.15rem 0.5rem;border-radius:0.25rem;" +
        "border:1px solid var(--color-border);background:var(--color-bg);color:var(--color-text-light)";

      button.addEventListener("click", function () {
        navigator.clipboard?.writeText(code);
        button.textContent = "Copied";
        setTimeout(function () { button.textContent = "Copy"; }, 2000);
      });

      block.style.position = "relative";
      block.append(button);
    });
  });
</script>
```

The code is read before the button is added, so the word "Copy" never ends up on the clipboard.

## What's allowed in head code

Only the tags that belong in the head of a page:

`<script>`, `<style>`, `<link>`, `<meta>`, `<noscript>` and `<template>`

Pagecord checks your code before saving it. If you paste something else, you'll see:

> can only contain \<script>, \<style>, \<link>, \<meta>, \<noscript> and \<template> tags. Move \<div> to the body code instead

This usually happens when a snippet has both a script and a visible element. Put the script part in **Head code** and the rest in **Body code**.

Body code accepts any HTML. Each box holds up to 8KB.

## Switching it off

If your blog starts misbehaving after you add something, untick **Enable custom code** and save. Your code is kept, it just stops running, which makes it easy to confirm whether custom code is the cause.

## What happens if I cancel

Unlike custom CSS and the custom footer, custom code stops running when your subscription ends. Nothing is deleted, so if you subscribe again it starts working straight away.
