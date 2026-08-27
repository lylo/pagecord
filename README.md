# Pagecord

Publish your writing effortlessly. All you need is email.

[https://pagecord.com](https://pagecord.com)

![](https://github.com/lylo/pagecord/actions/workflows/ci.yml/badge.svg)

## What this is

Pagecord is a personal blogging platform. Readers get fast, clean blogs on
their own subdomain or custom domain; writers publish however suits them –
by emailing their blog, in a rich text editor, from
[Obsidian](https://help.pagecord.com/obsidian), or through the API. It has
been in production since 2024, run by one person, and this repository is the
whole application.

## The stack

Vanilla Rails, deliberately: Rails 8 (tracking `main`) with Hotwire and
import maps, no JavaScript build step, Postgres, Sidekiq on Redis, and
Minitest with fixtures. Fat models, skinny controllers, RESTful routes.
The conventions the code follows are written down in [AGENTS.md](AGENTS.md).

## Finding your way around

- [architecture.md](architecture.md) – how the app is shaped and hosted,
  from routing to custom-domain SSL
- [docs/development.md](docs/development.md) – running it locally: Docker or
  native, processing emails, simulating billing, log analysis
- [docs/sysadmin/](docs/sysadmin/) – production operations notes
- [CONTRIBUTING.md](CONTRIBUTING.md) – the state of contributions

## Quick start

```bash
docker compose up
```

That starts Postgres, Redis, Memcached, Rails and the Tailwind watcher.
Visit [http://localhost:3000](http://localhost:3000), or a seeded blog at
[http://joel.localhost:3000](http://joel.localhost:3000). The full setup,
including native development without Docker, is in
[docs/development.md](docs/development.md).
