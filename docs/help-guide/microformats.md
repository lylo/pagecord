---
title: "Microformats"
published: false
---
Every Pagecord blog is marked up with [microformats](https://microformats.org) – small HTML conventions that let machines understand your content, not just humans. You don't need to do anything; it's built into every blog, free or premium.

## What Pagecord marks up

- **Posts** use `h-entry`, identifying the title (`p-name`), permalink (`u-url`), publication date (`dt-published`) and content (`e-content`).
- **Your post stream** uses `h-feed`, so tools can treat your home page as a feed of entries.
- **Your blog itself** uses `h-card` – the online equivalent of a business card – with your blog's name, URL and avatar.
- **Identity links** use `rel="me"` to declare that profiles elsewhere on the web belong to you. See [SEO & Discovery](seo-and-discovery.md).

## What's it good for?

Microformats are a cornerstone of the IndieWeb. Tools that understand them can do useful things with your blog without any screen-scraping:

- IndieWeb feed readers can present your posts properly – title, author, date and content – because your stream is a parseable `h-feed`.
- Mastodon, Threads and other services use `rel="me"` to verify that your blog and your profiles belong to the same person.
- Services like [IndieLogin](https://indielogin.com) can sign you in with your own domain.
- Publishing tools that speak [Micropub](micropub.md) build on the same ideas.

## See what a machine sees

Paste your blog's URL into the [microformats parser at pin13.net](https://pin13.net/mf2/) to see exactly what IndieWeb tools can read from it.
