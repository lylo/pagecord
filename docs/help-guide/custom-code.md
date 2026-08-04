---
title: "Adding custom code"
published: true
---

Premium customers can add their own HTML (including `<script>`) to every page of their blog. This is useful for things like:

- adding support for third party analytics, such as Plausible or Fathom
- site verification tags for search engines
- identity links for verifying your blog on Mastodon, without showing a social icon in your navigation
- adding dynamic features like a copy button for code blocks, or article progress bars

To add custom code, head over to **Settings** → **Custom Code**.

### A Quick Note

Custom code is an advanced feature. Anything you add runs on every page of your blog, so a broken snippet can break your whole site. Customer support for writing or debugging custom code is not possible.

## Head code and body code

There are two different code blocks you can customise:

**Head Code** is added just before the closing `</head>` tag. Most people use it for third party analytics, or for a verification tag another service has asked them to add.

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

## An example

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

**Register your listeners once.** Body code is re-run every time a reader moves to another page, so `document.addEventListener` inside it adds another listener each time. After ten pages you have ten copies of your script running, and anything that fetches from another service will do it ten times over. Set a flag on `window` and only register when it isn't there yet. Both examples below show the pattern.

**Don't add anything inside a code block.** Pagecord highlights code after the page has loaded, and it does so by replacing everything inside each `<pre>` element. Anything you've put in there is destroyed, and any text it contained gets swallowed into the code itself. Add your element next to the `<pre>`, not inside it. The copy button example below shows the pattern.

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

### Example: a copy button for code blocks

Adds a Copy button to the corner of every code block, which is handy if you write posts containing code. This goes in **Body code**:

```html
<script>
if (!window.copyButtonsReady) {
  window.copyButtonsReady = true;

  function addCopyButtons() {
    document.querySelectorAll(".post-body pre").forEach(function (block) {
      if (block.parentElement.classList.contains("copy-wrapper")) return;

      // Wrap the code block so the button can sit beside it rather than inside it
      const wrapper = document.createElement("div");
      wrapper.className = "copy-wrapper";
      wrapper.style.position = "relative";
      block.parentNode.insertBefore(wrapper, block);
      wrapper.append(block);

      const button = document.createElement("button");
      button.className = "copy-code";
      button.textContent = "Copy";
      button.style.cssText = "position:absolute;top:0.5rem;right:0.5rem;cursor:pointer;" +
        "font-size:0.75rem;padding:0.15rem 0.5rem;border-radius:0.25rem;" +
        "border:1px solid var(--color-border);background:var(--color-bg);color:var(--color-text-light)";

      button.addEventListener("click", function () {
        navigator.clipboard?.writeText(block.innerText);
        button.textContent = "Copied";
        setTimeout(function () { button.textContent = "Copy"; }, 2000);
      });

      wrapper.append(button);
    });
  }

  document.addEventListener("turbo:load", addCopyButtons);
  document.addEventListener("turbo:frame-load", addCopyButtons);
}
</script>
```

The button lives in a wrapper alongside the code block rather than inside it, so syntax highlighting can't destroy it. The code is read when the button is clicked, which means it always matches what the reader can see, and the word "Copy" never ends up on the clipboard.

If you put the button inside the `<pre>` instead, it works some of the time and not others, depending on whether highlighting happened to run before or after your script. When it loses that race the button disappears and the word "Copy" is left stranded at the end of your code.

### Example: a table of contents

Adds a linked contents list to the top of any post with a few headings in it, which is useful if you write long articles. Pages have a `{{ table_of_contents }}` variable for this, but posts don't, because it would end up in your RSS feed and your newsletter. Building it after the page loads avoids that. This goes in **Body code**:

```html
<script>
if (!window.tableOfContentsReady) {
  window.tableOfContentsReady = true;

  document.addEventListener("turbo:load", function () {
    if (document.body.dataset.pageType !== "post") return;
    if (document.querySelector(".toc")) return;

    const headings = document.querySelectorAll(".post-body h2, .post-body h3");
    if (headings.length < 3) return;

    const toc = document.createElement("details");
    toc.className = "toc";
    toc.open = true;
    toc.style.cssText = "margin:2rem 0;padding:0.75rem 1rem;font-size:0.875em;" +
      "background:var(--color-bg-subtle);border-radius:0.5rem";

    const summary = document.createElement("summary");
    summary.textContent = "Contents";
    summary.style.cssText = "cursor:pointer;color:var(--color-text-light)";
    toc.append(summary);

    const list = document.createElement("ol");
    list.style.cssText = "margin:0.5rem 0 0;padding-left:1.25rem";

    headings.forEach(function (heading, index) {
      // Older posts may not have been given a heading anchor yet
      if (!heading.id) heading.id = "section-" + (index + 1);

      const item = document.createElement("li");
      if (heading.tagName === "H3") item.style.marginLeft = "1rem";

      const link = document.createElement("a");
      link.href = "#" + heading.id;
      link.textContent = heading.textContent.trim();

      item.append(link);
      list.append(item);
    });

    toc.append(list);

    // Above the first heading, so your opening paragraphs stay at the top
    headings[0].before(toc);
  });
}
</script>
```

Pagecord gives every heading in a post an `id` when you save it, so the links have something to point at without you doing anything. Posts written a long time ago might not have them, so the script falls back to numbering the sections itself.

It only runs on single posts, which is why there's no `turbo:frame-load` here. Posts with fewer than three headings are left alone, so short posts stay clean. It picks up `h2` and `h3` – add `h4` to the selector if your posts go deeper – and it starts open, so remove `toc.open = true` if you'd rather readers had to click.

### Example: showing webmentions

[Webmentions](https://indieweb.org/Webmention) let other sites tell you when they've linked to your post. Pagecord already marks your posts up with microformats, so this is a natural fit. There are three steps.

**1. Sign up at [webmention.io](https://webmention.io).** It signs you in using your own blog address, which needs a `rel="me"` link pointing at somewhere it can verify you, like GitHub. Pagecord adds one automatically for every social link in your navigation apart from RSS and Web, so adding a GitHub link in **Settings** → **Navigation** is enough. If you'd rather not show the icon, add the link in **Head code** instead, as above.

**2. Advertise your endpoints.** This goes in **Head code**:

```html
<link rel="webmention" href="https://webmention.io/yourblog.pagecord.com/webmention">
<link rel="pingback" href="https://webmention.io/yourblog.pagecord.com/xmlrpc">
```

Replace `yourblog.pagecord.com` with your own blog address, and use your custom domain if you have one.

**3. Show them on your posts.** webmention.io only collects mentions, so nothing appears on your blog until you ask for them. This goes in **Body code**:

```html
<script>
if (!window.webmentionsReady) {
  window.webmentionsReady = true;

  document.addEventListener("turbo:load", async function () {
    if (document.body.dataset.pageType !== "post") return;
    if (document.querySelector(".webmentions")) return;

    const footer = document.querySelector("article footer");
    if (!footer) return;

    const target = document.querySelector("link[rel=canonical]")?.href || location.href;

    try {
      const response = await fetch("https://webmention.io/api/mentions.jf2?per-page=100&target=" + encodeURIComponent(target));
      if (!response.ok) return;

      const mentions = (await response.json()).children || [];
      if (!mentions.length) return;

      // One entry per person, since the same site often mentions you more than once
      const people = new Map();
      for (const mention of mentions) {
        const name = mention.author?.name || new URL(mention.url).hostname;
        if (!people.has(name)) people.set(name, mention.url);
      }

      const shown = [...people].slice(0, 10);
      const hidden = people.size - shown.length;

      const list = document.createElement("p");
      list.className = "webmentions";
      list.style.cssText = "margin-top:1.5rem;font-size:0.875em;color:var(--color-text-light)";
      list.append(people.size === 1 ? "1 mention from around the web: " : people.size + " mentions from around the web: ");

      // Built up node by node rather than with innerHTML: these names come from
      // other people's websites, and must never be treated as HTML
      shown.forEach(function ([name, url], index) {
        if (index) list.append(", ");
        const link = document.createElement("a");
        link.href = url;
        link.rel = "nofollow ugc";
        link.textContent = name;
        list.append(link);
      });

      if (hidden) list.append(" and " + hidden + " others");

      // After the footer, not inside it: the footer is a flex row
      footer.after(list);
    } catch (error) {
      // Leave the post exactly as it was if webmention.io can't be reached
    }
  });
}
</script>
```

It asks for the canonical address of the post, which is what other sites link to, and adds nothing at all when there are no mentions yet. Some mentions arrive without an author name, so those fall back to the name of the site they came from. Repeat mentions from the same person are counted once, and only the first ten are named.

Note that the names are added to the page one node at a time rather than with `innerHTML`. They come from other people's websites, so treating them as HTML would let someone else run code on your blog. It's worth keeping that shape if you adapt this.

## What's allowed in head code

Only the tags that belong in the head of a page:

`<script>`, `<style>`, `<link>`, `<meta>`, `<noscript>` and `<template>`

Pagecord checks your code before saving it. If you paste something else, you'll see:

> can only contain \<script>, \<style>, \<link>, \<meta>, \<noscript> and \<template> tags. Move \<div> to the body code instead

This usually happens when a snippet has both a script and a visible element. Put the script part in **Head code** and the rest in **Body code**.

Body code accepts any HTML. Each box holds up to 8KB.

## Switching it off

If your blog starts misbehaving after you add something, untick **Head and body code enabled**. Your code is kept, it just stops being added to your pages, which makes it easy to rule out as the cause. Custom CSS and your custom footer are not affected.

## What happens if I cancel

Unlike custom CSS and the custom footer, custom code stops running when your subscription ends. Nothing is deleted, so if you subscribe again it starts working straight away.
