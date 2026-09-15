---
name: pagecord-cli
description: Design and publish a Pagecord blog with the `pagecord` CLI. Use when the user wants to restyle their blog, change its theme, font, layout or colours, edit its custom CSS, add custom head or footer code, or publish and update posts from local files.
allowed-tools: Bash, Read, Write, Edit, WebFetch
---

# Pagecord CLI

Everything here runs through the `pagecord` command.

## Read the docs before writing CSS

The custom CSS guide is the authority on a blog's HTML structure and on what
Pagecord will accept. Read it before your first CSS change in a session. It
documents every class you can target, the page structure, and worked examples
for the things people usually ask for.

In a Pagecord checkout it is `docs/help-guide/custom-css.md`, and that copy is
ahead of the published one. Otherwise fetch
`https://help.pagecord.com/custom-css`.

`https://help.pagecord.com/pagecord-cli` covers the CLI itself.

Do not work out the structure by scraping the page. Comments in particular are
loaded on demand, so they are absent from the page source entirely.

## What Pagecord rejects

Custom CSS is validated on save, and a rejected update changes nothing:

- 16KB maximum
- `@import` only over HTTPS, and only from Google Fonts or Bunny Fonts
- **No nested CSS.** Write flat selectors, not `.post { .title { ... } }`
- Custom properties, logical properties, `@supports` and `@layer` are fine

## Before you start

The user needs the gem and a saved login:

```bash
gem install pagecord-cli
pagecord login SUBDOMAIN     # prompts for a key from Settings > API
```

`pagecord blog list` shows what is already configured. If it prints nothing,
stop and ask the user to log in; do not try to create a key yourself.

With several blogs configured, pass `--blog SUBDOMAIN` on every command, or run
`pagecord blog use SUBDOMAIN` once to set a default. API keys are per blog.

## Restyling a blog

Custom CSS is a single field. `update` replaces it wholesale, so always pull it
down first and keep that file as the backup:

```bash
pagecord custom-code show --css --blog myblog > blog.css
cp blog.css blog.css.orig
```

Look at the current settings before changing anything, since the theme already
sets colours and fonts your CSS has to work with rather than fight:

```bash
pagecord appearance show --blog myblog
```

Edit `blog.css`, show the user a diff, then push it:

```bash
pagecord custom-code update --css blog.css --blog myblog
```

Reverting is `pagecord custom-code update --css blog.css.orig --blog myblog`.
Tell the user that, so they know the change is cheap to undo.

Prefer overriding the theme's custom properties over restyling elements one by
one, because they cascade correctly in both light and dark mode:

```css
:root {
  --theme-bg: #faf7f0;
  --theme-text: #2b2b2b;
  --theme-accent: #8c5a3c;
  --font-body: Georgia, serif;
  --font-size-base: 112.5%;
}
```

Scope rules with the attributes on `<body>` rather than inventing wrappers:
`data-page-type` is one of `index`, `home-page`, `page` or `post`, and
`data-slug` is the slug of the post or page being viewed.

Classes containing `lexxy` are an editor implementation detail and may be
renamed without warning. Target `.post-body`, never `.lexxy-content`.

Whole-theme changes belong in `appearance update`, not CSS:

```bash
pagecord appearance update --theme sand --font serif --blog myblog
```

Fields are `--theme`, `--font`, `--width`, `--layout`, the six
`--custom-theme-*` colours and `--show-branding true|false`.

If the user is not attached to hand-written CSS, mention the Theme Garden in
their settings, which applies curated templates in one click.

## Custom head and footer code

`--footer-html`, `--head-html` and `--body-html` work exactly like `--css` and
each take a file path. `--enabled true|false` switches head and body code off
without deleting it.

## Publishing posts

```bash
pagecord publish hello.md            # publish or update a post
pagecord draft notes/idea.md         # save it as a draft instead
```

The first publish writes a `pagecord_token` into the file's front matter and
later runs update that same post. Removing the token makes the next publish
create a new one. Local images referenced as `![alt](photo.jpg)` are uploaded.

## Always verify

After any change, load the blog and check it looks right. A successful `update`
only means the CSS was saved, so never report a redesign as done on that alone.

## Running against a local Pagecord

For a development server, log in with `--base-url` and the `api.` host:

```bash
pagecord login myblog --base-url http://api.localhost:3000
```

The prefix matters: Pagecord routes API requests on it. Needs CLI 0.2.2 or
newer. The base URL is saved with the blog, so pass it at login only.
