---
title: "Publishing from Obsidian"
published: true
published_at: 2026-03-16T12:00:00+00:00
---

You can write you blog posts in Obsidian and publish directly from there to your Pagecord blog using the official [Pagecord plugin](https://community.obsidian.md/plugins/pagecord). All the details are on the plugin home page, but a quick guide is below.

## Setup

1. [Enable the API](/api) in your Pagecord blog settings and copy your API key
2. In Obsidian, go to **Settings → Community Plugins → Browse** and install **Pagecord**
3. In **Settings → Pagecord**, paste your API key

## Usage

Open the command palette (`Cmd/Ctrl + P`) and run **Publish to Pagecord** or **Publish as draft to Pagecord**.

The plugin reads optional YAML frontmatter (`title`, `slug`, `tags`, `published_at`, `canonical_url`, `hidden`, `locale`) and uploads embedded images automatically. Full details are [on the plugin home page](https://community.obsidian.md/plugins/pagecord).


