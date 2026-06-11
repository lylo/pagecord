---
title: "Publishing with the Pagecord CLI"
published: true
published_at: 2026-06-11T00:00:00+00:00
---

The Pagecord CLI lets you publish local Markdown and HTML files to your Pagecord blog from the command line. It is useful if you write in a local folder, use an editor like Vim, Emacs, iA Writer, or VS Code, or want to publish from scripts and automation.

The CLI is a Premium feature because it uses the Pagecord API.

## Installation

The CLI is published as a Ruby gem:

```bash
gem install pagecord-cli
```

This installs the `pagecord` command.

## Setup

First, [enable the API](/api) in your Pagecord blog settings and copy your API key.

Then log in from your terminal using your blog subdomain:

```bash
pagecord login myblog
```

For example, if your blog is `myblog.pagecord.com`, use `myblog`.

The command asks for your API key and stores it locally in `~/.pagecord.yml`.

## Publishing

To publish a local Markdown or HTML file:

```bash
pagecord publish post.md
```

To save or update a draft:

```bash
pagecord draft post.md
```

The first publish creates a post and writes Pagecord metadata back into the file. Later publishes update the same post.

If you want to move a published post back to draft, run `draft` on the same file:

```bash
pagecord draft post.md
```

To delete a post, use the Pagecord dashboard.

## Multiple blogs

You can log in to more than one Pagecord blog:

```bash
pagecord login personal
pagecord login work
```

List configured blogs:

```bash
pagecord list
```

If only one blog is configured, `publish` and `draft` can omit the subdomain. If you have more than one, pass the subdomain as the final argument:

```bash
pagecord publish post.md personal
pagecord draft post.md work
```

Remove a saved blog:

```bash
pagecord logout personal
```

## Options

`publish` and `draft` accept options for common post settings:

```bash
pagecord publish post.md --title "Custom title"
pagecord publish post.md --slug my-post
pagecord publish post.md --published-at 2026-06-11
pagecord publish post.md --tags ruby,cli
pagecord publish post.md --canonical-url https://example.com/original
pagecord publish post.md --hidden
pagecord publish post.md --locale en
```

Use `--title ""` to publish a post without a title.

## Frontmatter

Markdown files can include Pagecord-compatible YAML frontmatter:

```yaml
---
title: My Post
slug: my-post
tags:
  - ruby
  - cli
published_at: 2026-06-11T12:00:00Z
canonical_url: https://example.com/original
hidden: false
locale: en
---
```

All fields are optional. If `title` is omitted, the CLI uses the filename. Use `title:` or `title: ""` to publish without a title.

After publishing, the CLI manages Pagecord metadata in the file:

```yaml
pagecord_token: 65b82933
pagecord_blog_fingerprint: c92376aeb770
pagecord_attachments:
status: published
```

Do not edit these fields unless you know what you are doing. `pagecord_token` links the file to the Pagecord post so future publishes update it instead of creating a duplicate. Delete `pagecord_token` only if you want the next publish to create a new post.

## Images

Markdown image references to local files are uploaded to Pagecord automatically:

```markdown
![Alt text](photo.jpg)
![[photo.jpg]]
```

Supported local image types are JPEG, PNG, GIF, and WebP. External image URLs and HTML `<img>` tags are left alone.

## Using the CLI with Obsidian

The Pagecord CLI and [Obsidian plugin](obsidian.md) use the same Pagecord frontmatter for Markdown files. That means you can move between them:

- A post first published from the CLI can later be edited and synced from Obsidian
- A note first published from Obsidian can later be updated from the CLI

Make sure both tools are configured with the same Pagecord blog API key. If a file is linked to another configured blog, the CLI will refuse to update it.

## Source code

The CLI is open source on GitHub: [github.com/lylo/pagecord-cli](https://github.com/lylo/pagecord-cli).
