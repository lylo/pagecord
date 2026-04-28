# Pagecord

Publish your writing effortlessly. All you need is email.

[https://pagecord.com](https://pagecord.com)

![](https://github.com/lylo/pagecord/actions/workflows/ci.yml/badge.svg)

## Development

### Quick Start with Docker

The easiest way to get Pagecord running locally is with Docker. `docker compose up` is the Docker equivalent of `bin/dev` — it starts PostgreSQL, Redis, Memcached, the Rails server, and the Tailwind watcher all in one go.

First, install [Docker Desktop](https://www.docker.com/products/docker-desktop/) and make sure it's running.

Then:

```bash
git clone https://github.com/lylo/pagecord.git
cd pagecord
docker compose up
```

This stays running in your terminal. Open a second terminal for running commands.

You can view the app at [http://localhost:3000](http://localhost:3000). You can view individual blogs on their respective subdomains, e.g. [http://joel.localhost:3000](http://joel.localhost:3000). Note: Safari doesn't support `*.localhost` subdomains - use `lvh.me` instead (e.g. [http://joel.lvh.me:3000](http://joel.lvh.me:3000)).

### After pulling changes

```bash
# Rebuild the image (needed when Gemfile or Dockerfile changes)
docker compose up --build

# Clear stale CSS (needed when Tailwind output looks wrong or out of date)
docker compose exec web rake assets:clobber
```

Your local files are mounted into the container, so changes to `.erb` views and Ruby files take effect immediately. But compiled assets like `app/assets/builds/tailwind.css` can become stale — if the UI looks wrong after pulling, clear them with `assets:clobber` and the Tailwind watcher will regenerate.

### Running commands in Docker

With `docker compose up` running in one terminal, use a second terminal for one-off commands:

```bash
# Rails console
docker compose exec web bin/rails console

# Run tests
docker compose exec web bin/rails test
docker compose exec web bin/rails test:system

# Run migrations
docker compose exec web bin/rails db:migrate

# Process emails (debug)
docker compose exec web bash -c "DIR=tmp/emails rake email:load"
```

### Native Development (Alternative)

If you prefer to run Rails natively without Docker:

<details>
<summary>Click to expand native setup instructions</summary>

Install Ruby 3.4.5+ using [HomeBrew](https://brew.sh/) and [rbenv](https://github.com/rbenv/rbenv).

```bash
bundle install
rails db:setup
brew install redis postgresql
bin/dev
```

Run tests:
```bash
bin/rails test
bin/rails test:system
```

</details>

## Processing an email locally

Sometimes you'll need to debug emails. To do this, save the .eml file(s) to a folder
such as `tmp/emails`.

You can then run the following command which will parse all the .eml files in that
folder and create posts for the first user account in the seed data (`joel@pagecord.com`).

```bash
DIR=tmp/emails rake email:load
```

## Open Graph Images

Pagecord can optionally generate dynamic Open Graph images for blog posts using a separate Cloudflare Worker service. This worker is currently **closed source** and not required to run Pagecord locally.

**What it does**: Generates social media preview images for posts without explicit OG images.

**Local development**: Pagecord gracefully falls back to standard behavior when the worker is not configured. Your local installation will work perfectly fine without it - posts will simply use their first image or no OG image, just like they did originally.

If you're interested in setting up your own OG image worker, you can configure it with these optional environment variables:
```bash
OG_WORKER_URL=https://your-worker-url.com/og
OG_SIGNING_SECRET=your-secret-key
```

## Log Analysis

Rake tasks for analysing production logs on the server. No external gems required.

```bash
# Per-hour request overview — highlights anomalous traffic spikes
rake logs:overview

# Full report for a day (5 tables: requests/hour, endpoints, IPs, user agents, hosts)
rake "logs:report[2026-02-23]"

# Drill into a specific hour (requests/minute instead of per-hour)
rake "logs:report[2026-02-23,21]"

# Live tail with per-minute request counter (alerts at >500 req/min)
rake logs:watch

# Traffic report for a specific blog (all available logs)
rake "logs:blog[joel]"

# Scoped to a specific date
rake "logs:blog[joel,2026-02-23]"

# Scoped to a specific hour
rake "logs:blog[joel,2026-02-23,21]"

# Works with custom domains too
rake "logs:blog[example.com]"
```

## More info

Read about [the Pagecord architecture](architecture.md) or [making contributions](CONTRIBUTIONS.md).

Follow the [Pagecord blog](https://pagecord.com/blog).

<a href="https://www.buymeacoffee.com/heyolly" target="_blank"><img src="https://cdn.buymeacoffee.com/buttons/v2/default-red.png" alt="Buy Me A Coffee" style="height: 50px !important;width: 178px !important;" ></a>