---
title: "Publishing from Obsidian"
published: true
published_at: 2026-03-16T12:00:00+00:00
---

Publish notes from [Obsidian](https://obsidian.md) to your Pagecord blog using the official plugin. Write in Obsidian, hit a command, done.

## Installation

The plugin is pending review in the Obsidian community directory. For now, install it manually:

```
git clone https://github.com/lylo/obsidian-pagecord.git
cd obsidian-pagecord
mkdir -p /path/to/your/vault/.obsidian/plugins/obsidian-pagecord
cp main.js manifest.json /path/to/your/vault/.obsidian/plugins/obsidian-pagecord/
```

Then in Obsidian, go to **Settings → Community Plugins**, turn off **Restricted mode** if needed, then enable **Pagecord**.

Once the plugin is accepted into the community directory you'll be able to install and update it directly from Obsidian.

## Setup

1. In your Pagecord dashboard, go to **Settings → API** and generate an API key
2. In Obsidian, go to **Settings → Pagecord** and paste your API key

## Publishing

Open the command palette (`Cmd/Ctrl + P`) and run:

- **Publish to Pagecord** — publishes the current note
- **Publish as draft to Pagecord** — saves it as a draft

Commands are only available when a markdown file is open.

## Updating posts

After publishing, the plugin adds a `pagecord_token` to your note's frontmatter. This links the note to the Pagecord post — future publishes update the existing post instead of creating a duplicate.

Delete `pagecord_token` from the frontmatter if you want to publish as a new post.

## Frontmatter

Use YAML frontmatter to set post metadata:

```yaml
---
title: My Post Title
slug: my-post-title
tags: [personal, update]
status: published
published_at: 2026-01-15T10:00:00Z
canonical_url: https://example.com/original
hidden: false
locale: en
---
```

All fields are optional. Without a `title`, the filename is used. Set `title: false` to create a post with no title.

The `status` field overrides the command — so a note with `status: draft` will always publish as a draft, even if you use the "Publish to Pagecord" command.

## Images

Embedded images are uploaded to Pagecord automatically. Both syntaxes work:

- `![[photo.jpg]]`
- `![](photo.jpg)`

Supported formats: JPEG, PNG, GIF, and WebP. The plugin caches uploaded image data in a `pagecord_attachments` frontmatter field so unchanged files aren't re-uploaded on subsequent publishes.

## Troubleshooting

**"Invalid API key"** — Check that your API key is correct in **Settings → Pagecord**. You can regenerate it from your Pagecord dashboard.

**"Premium subscription required"** — The API is a premium feature. Upgrade from your Pagecord billing settings.

**Post keeps creating duplicates** — Make sure the `pagecord_token` field in your frontmatter isn't being removed between publishes.

**Images not appearing** — Check that the image file exists in your vault and uses a supported format (JPEG, PNG, GIF, WebP).
