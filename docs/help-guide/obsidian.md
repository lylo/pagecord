---
title: "Publishing from Obsidian"
published: true
published_at: 2026-03-16T12:00:00+00:00
---

You can write your blog posts in Obsidian and publish directly from there to your Pagecord blog using the official [Pagecord plugin](https://community.obsidian.md/plugins/pagecord). All the details are on the plugin home page, but a quick guide is below.

## Setup

1. [Enable the API](/api) in your Pagecord blog settings and copy your API key
2. In Obsidian, go to **Settings → Community Plugins → Browse** and install **Pagecord**
3. In **Settings → Pagecord**, click the **+** icon under **Pagecord Blog Connections**
4. Enter a blog name and API key, then click **Save**

The blog name is only used inside Obsidian, so choose something that will make sense in the command palette. If you publish to more than one Pagecord blog, add another connection in the same settings screen.

## Usage

Open the command palette (`Cmd/Ctrl + P`) and run the command for the blog you want to publish to:

- **Publish to Blog Name** creates or updates the post as published
- **Publish to Blog Name (draft)** creates or updates the post as a draft

Each saved blog connection gets its own pair of publish commands. A post is linked to one Pagecord blog at a time, so updates continue using the same blog connection that first published the note.

The plugin reads optional YAML frontmatter (`title`, `slug`, `tags`, `published_at`, `canonical_url`, `hidden`, `locale`) and uploads embedded images automatically. After publishing, it manages Pagecord metadata in the note frontmatter so future publishes update the existing post. Existing notes published before multi-blog support continue to work.

Full details are [on the plugin home page](https://community.obsidian.md/plugins/pagecord).
