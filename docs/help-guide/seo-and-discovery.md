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

Identity links tell other services that profiles elsewhere on the web belong to the same person as your blog. Mastodon, Threads and IndieAuth use them to verify you – this is what gets you the green verified tick on a Mastodon profile.

Add one URL per line (e.g. `https://mastodon.social/@you` or `https://github.com/you`). For verification to work, your profile on that service must also link back to your blog – on Mastodon, add your blog URL to your profile metadata and re-save it.

Your social navigation links are included automatically, except your RSS feed and any generic "Web" links (which might point at a site that isn't yours) – so you only need to add links here that aren't already covered.

rel=me is one of several [microformats](microformats.md) built into every Pagecord blog.

## Discoverability

By default, your blog can be found through search engines and may be featured in the Pagecord Spotlight and Shuffle. If you'd prefer to keep things low-key, untick the "Make my blog discoverable" box – Pagecord will serve a `robots.txt` that discourages search engines, and exclude your blog from Spotlight and Shuffle.

## AI Crawlers

Pagecord blocks AI training crawlers (such as GPTBot and ClaudeBot) in your blog's `robots.txt` by default, so your writing isn't used to train AI models. AI search engines can still index and cite your posts, and AI assistants can read a post when a reader asks about it – so your blog stays discoverable without feeding the training pipelines.
