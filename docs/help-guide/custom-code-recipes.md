---
title: "Custom code recipes"
published: true
---

These are custom code snippets you can paste straight into **Settings** → **Custom Code**. Each one is self-contained, so take only the ones you want.

Read [Adding custom code](custom-code.md) first if you haven't already, particularly the section on writing your own scripts. Pagecord uses Turbo, so a script written the ordinary way will run once and then quietly stop working.

If you build a fun recipe, [please let me know](https://help.pagecord.com/support) and I'll consider adding it to this page.

> Note: These recipes run on every page of your blog. If one of them misbehaves, untick **Head and body code enabled** to switch your code off without deleting it. Customer support for writing or debugging custom code is not possible.

<div>
{{ table_of_contents | heading: "Table of Contents" }}
</div>

---

## Using more than one recipe

Recipes stack. Paste them one after another, each keeping its own `<script>` tags:

```html
<script>
if (!window.copyButtonsReady) {
  // the first recipe
}
</script>

<script>
if (!window.tableOfContentsReady) {
  // the second recipe
}
</script>
```

Browsers run the blocks in the order you paste them, and separate blocks share the same global scope, so the `window` flag each recipe sets to avoid running twice still does its job.

You could merge everything into one `<script>` block instead, and it would work, but keeping them separate is safer. Each block is compiled on its own, so a typo in one recipe stops that recipe rather than all of them.

Don't put a `<script>` inside another one. The browser ends the outer block at the first `</script>` it finds, and the rest of your code spills onto the page as text.

The 8KB limit applies to the whole box rather than to each snippet. Every body code recipe here, pasted together, comes to just under 5KB.

## A copy button for code blocks

Adds a Copy button to the corner of every code block, which is handy if you write posts containing code. This goes in **Body code**:

```javascript
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

## A table of contents for posts

Adds a linked contents list to the top of any post with a few headings in it, which is useful if you write long articles. Pages have a `{{ table_of_contents }}` variable for this, but posts don't, because it would end up in your RSS feed and your newsletter. Building it after the page loads avoids that. This goes in **Body code**:

```javascript
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
    toc.style.cssText = "margin:2rem 0;padding:0.75rem 1rem;font-size:0.875em;border-radius:0.5rem";

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

## Showing webmentions

[Webmentions](https://indieweb.org/Webmention) let other sites tell you when they've linked to your post. Pagecord already marks your posts up with microformats, so this is a natural fit. There are three steps.

**1. Sign up at [webmention.io](https://webmention.io).** It signs you in using your own blog address, which needs a `rel="me"` link pointing at somewhere it can verify you, like GitHub. Pagecord adds one automatically for every social link in your navigation apart from RSS and Web, so adding a GitHub link in **Settings** → **Navigation** is enough. If you'd rather not show the icon, add the link in **Head code** instead, as described in [Adding custom code](custom-code.md).

**2. Advertise your endpoints.** This goes in **Head code**:

```html
<link rel="webmention" href="https://webmention.io/yourblog.pagecord.com/webmention">
<link rel="pingback" href="https://webmention.io/yourblog.pagecord.com/xmlrpc">
```

Replace `yourblog.pagecord.com` with your own blog address, and use your custom domain if you have one. It has to be the same address you signed in to webmention.io with, because that's the account mentions are collected under. Sign in with the address your posts are actually published at, or nothing will reach you.

**3. Show them on your posts.** webmention.io only collects mentions, so nothing appears on your blog until you ask for them. This goes in **Body code**:

```javascript
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

**Where mentions actually come from.** Once all this is in place your posts will still look exactly the same, because a webmention has to be sent to you by another site, and most sites don't send them. Other blogs that support webmentions will do it on their own. Social networks won't, so you need [Bridgy](https://brid.gy), which watches your account and forwards responses to your posts as webmentions. Connect the account you already have, and ignore the option to connect your site directly to the fediverse – that's a different service that turns your blog into its own social account. Bridgy supports Mastodon, Bluesky, Flickr, GitHub and Reddit. It no longer supports Twitter/X, and LinkedIn was never supported.

Posting a link to your blog doesn't create a mention by itself. Bridgy sends one when somebody likes, boosts or replies to that post, so nothing appears until someone responds. If you want to see it working without waiting, like your own post from a second account.
