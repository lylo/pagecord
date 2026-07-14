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

## Discoverability

By default, your blog can be found through search engines and may be featured in the Pagecord Spotlight and Shuffle. If you'd prefer to keep things low-key, untick the "Make my blog discoverable" box – Pagecord will serve a `robots.txt` that discourages search engines, and exclude your blog from Spotlight and Shuffle.

## AI Crawlers

Pagecord blocks AI training crawlers (such as GPTBot and ClaudeBot) in your blog's `robots.txt` by default, so your writing isn't used to train AI models. AI search engines can still index and cite your posts, and AI assistants can read a post when a reader asks about it – so your blog stays discoverable without feeding the training pipelines.

If you have a subscription, you can customise the crawler rules section of your `robots.txt` in **Settings → Blog Settings** – for example, to unblock a crawler you're happy with. The default rules (search engine access and your sitemap location) always apply and can't be changed.
