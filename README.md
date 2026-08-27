# Pagecord

Blog without the slog.

[https://pagecord.com](https://pagecord.com)

![](https://github.com/lylo/pagecord/actions/workflows/ci.yml/badge.svg)

## Say, what?

Pagecord is a personal website and blogging platform. Simple to use,
powerful under the hood.

## The stack

Vanilla Rails (8), Hotwire, import maps, Postgres, Sidekiq, and
Minitest with fixtures. Fat models, skinny controllers, RESTful
routes. All that.

The conventions the code follows are written down in
[AGENTS.md](AGENTS.md).

## Finding your way around

- [architecture.md](architecture.md) – how the app is shaped and hosted.
- [docs/development.md](docs/development.md) – running it locally: Docker or
  native, processing emails, simulating billing, log analysis.
- [docs/sysadmin/](docs/sysadmin/) – production operations notes.
- [CONTRIBUTING.md](CONTRIBUTING.md)

## Quick start

```bash
docker compose up
```

That starts Postgres, Redis, Memcached, Rails and the Tailwind watcher (the app
side uses Tailwind... for now).

Visit [http://localhost:3000](http://localhost:3000), or a seeded blog at
[http://joel.localhost:3000](http://joel.localhost:3000). The full setup,
including native development without Docker, is in
[docs/development.md](docs/development.md).
