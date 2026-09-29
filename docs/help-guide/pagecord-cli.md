---
title: "Publishing with the Pagecord CLI"
published: true
published_at: 2026-06-11T00:00:00+00:00
---

The Pagecord CLI lets you publish local Markdown and HTML files to your Pagecord blog from the command line, read and edit your posts and pages, and change your blog's appearance and custom code. It is useful if you write in a local folder, use an editor like Vim, Emacs, iA Writer, or VS Code, want to publish from scripts and automation, or work with an AI agent such as Claude Code.

The CLI is a Premium feature because it uses the Pagecord API.

<div>
{{ table_of_contents | heading: "Table of Contents" }}
</div>

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

## Multiple blogs

You can log in to more than one Pagecord blog:

```bash
pagecord login personal
pagecord login work
```

List configured blogs:

```bash
pagecord blog list
```

If only one blog is configured, you don't need to say which one to use. If you have more than one, set a default, or pass `--blog` to any command:

```bash
pagecord blog use personal
pagecord post list --blog work
```

`publish` and `draft` also accept the subdomain as the final argument:

```bash
pagecord publish post.md work
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
pagecord publish post.md --no-hidden
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

## Posts and pages

You can also work with posts that aren't in a local file. Every post and page has a short token, such as `aaa33a9b`, which the list shows.

```bash
pagecord post list
pagecord post list --drafts
pagecord post show aaa33a9b
```

Lists show 15 posts at a time, newest first. Use `--page 2` for the next 15.

`show` prints the post's details followed by its content as HTML. To change a post, save the content to a file, edit it, and send it back:

```bash
pagecord post update aaa33a9b --content-file post.html
pagecord post update aaa33a9b --title "New title" --status draft
```

`update` only changes what you pass. `--content-file` sends Markdown if the file ends in `.md`, and HTML otherwise. It accepts the same options as `publish`, plus `--status draft` or `--status published`.

To create or delete a post:

```bash
pagecord post create --title "Hello" --content-file hello.md --status draft
pagecord post delete aaa33a9b
```

Deleting moves a post to the bin. Add `--permanent` to delete it for good.

Pages work the same way with `pagecord page`, for example `pagecord page list`.

Add `--json` to any command for output you can use in scripts.

## Appearance and custom code

Show and change your theme, font, width and layout:

```bash
pagecord appearance show
pagecord appearance update --theme sand --font serif
```

Custom CSS, head, body and footer code each take a file:

```bash
pagecord custom-code show --css > blog.css
pagecord custom-code update --css blog.css
pagecord custom-code update --footer-html footer.html
```

An update replaces the whole field, so keep a copy of the original. See [Custom CSS](custom-css.md) for what you can style.

## Using the CLI with an AI agent

The CLI includes a skill that teaches AI agents such as Claude Code how to use it:

```bash
pagecord skill install
```

This installs the skill to `~/.agents/skills/pagecord` and links it into `~/.claude/skills`. Run it again after updating the CLI with `gem update pagecord-cli`. You can then ask your agent to list your drafts, edit a post, or restyle your blog.

Check which version you have with `pagecord version`.

## Using the CLI with Obsidian

The Pagecord CLI and [Obsidian plugin](obsidian.md) use the same Pagecord frontmatter for Markdown files. That means you can move between them:

- A post first published from the CLI can later be edited and synced from Obsidian
- A note first published from Obsidian can later be updated from the CLI

Make sure both tools are configured with the same Pagecord blog API key. If a file is linked to another configured blog, the CLI will refuse to update it.

## Source code

The CLI is open source on GitHub: [github.com/lylo/pagecord-cli](https://github.com/lylo/pagecord-cli).
