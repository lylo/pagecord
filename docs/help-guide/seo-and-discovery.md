---
title: "SEO & Discovery"
published: true
published_at: 2026-02-13T12:00:00+00:00
---

Pagecord has a few settings to help search engines and social platforms understand your blog. You'll find these in **Settings → Blog Settings**.

## SEO Blog Title

By default, your blog name is used in the HTML title tag for search engines and social sharing. If you want something different to appear in search results – like "Ben's Blog - Thoughts on technology" – you can set that as an SEO title override.

## Google Site Verification

If you use [Google Search Console](https://search.google.com/search-console), you can add your verification code here. Pagecord will add the appropriate `<meta>` tag to your blog's HTML.

Just paste the verification code (or the full meta tag – Pagecord will extract the code automatically).

## Fediverse Author Attribution

If you're on Mastodon or another Fediverse platform, you can enter your Fediverse username (e.g. `@you@mastodon.social`) so that your posts are attributed to you when shared on those platforms.

## Identity Links (rel=me)

Pagecord adds a `rel="me"` link to your blog's HTML for each social link in your navigation, except your RSS feed and generic "Web" links (which might point at a site that isn't yours). These tell other services that those profiles belong to the same person as your blog – it's what gets you the green verified tick on a Mastodon profile.

Verification is reciprocal: your profile on the other service must also link back to your blog. On Mastodon, add your blog's URL to your profile metadata and re-save it.

rel=me is one of several [microformats](microformats.md) built into every Pagecord blog.

## Discoverability

By default, your blog can be found through search engines and may be featured in the Pagecord Spotlight and Shuffle. If you'd prefer to keep things low-key, untick the "Make my blog discoverable" box – Pagecord will serve a `robots.txt` that discourages search engines, and exclude your blog from Spotlight and Shuffle.

## AI Crawlers

Pagecord blocks AI training crawlers (such as GPTBot and ClaudeBot) in your blog's `robots.txt` by default, so your writing isn't used to train AI models. AI search engines can still index and cite your posts, and AI assistants can read a post when a reader asks about it – so your blog stays discoverable without feeding the training pipelines.

## Custom Crawler Rules

If you have a subscription, you can take control of the crawler rules in your blog's `robots.txt`. In **Settings → Blog Settings**, tick "Use custom crawler rules" and an editor will appear, pre-filled with Pagecord's default rules as a starting point – delete a crawler's entry to allow it, or add rules of your own.

A few things to know:

- Your custom rules replace Pagecord's default AI crawler block entirely. Any crawler you remove from the list will no longer be blocked.
- The core rules – search engine access and your sitemap location – always apply and can't be changed, so there's no need to add a `Sitemap` line (in fact, it isn't allowed).
- Supported directives are `User-agent`, `Allow`, `Disallow` and `Crawl-delay`. Comments starting with `#` are fine, and `Allow`/`Disallow` paths must start with `/`.
- To restore Pagecord's defaults, untick the box and save.

If your subscription lapses, the default rules take over again. And if your blog isn't discoverable (see above), search engines are discouraged entirely and custom crawler rules don't apply.
