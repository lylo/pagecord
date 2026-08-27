# Pagecord Architecture

Pagecord is a fully featured personal website and blogging app. It's a Rails app hosted by Hetzner, in Falkenstein, Germany.

## Web app

Pagecord is a web app that uses [Rails](https://rubyonrails.org) 8 and associated tech like Turbo, Stimulus and Import Maps. It runs on the Ruby version pinned in `.ruby-version`. It uses Memcached for caching.

## The shape of the app

One Rails app serves several very different audiences, split by routing
constraints and controller namespaces. The namespaces drive the shape of
everything else, including `test/controllers/`:

- `Blogs::` – the public, reader-facing blogs. Constraint-based routing serves
  them on `*.pagecord.com` subdomains and on customers' custom domains; the
  constraint classes live in `app/constraints`. These pages never authenticate.
- `App::` – the signed-in dashboard at `/app`: posts, pages, settings,
  analytics. A user `has_many` blogs (the oldest is the primary), and
  `Current.blog` carries the one being managed.
- `Api::` – token-authenticated JSON for the CLI, Obsidian plugin and
  third-party clients, plus a Micropub endpoint.
- `Admin::` – operator tools: moderation, deliverability, analytics.
- `Public::` – the marketing pages on the apex domain.
- `Billing::` – Paddle's webhooks.

Posting by email, the founding feature, flows: Postmark inbound webhook →
ActionMailbox → `PostsMailbox` → `MailParser`, whose HTML pipeline (body
extraction, image unfurling, inline attachments, tag extraction,
sanitisation) turns an email into a `Post`.

## Database

The database is managed Postgres 18 on [Ubicloud](https://www.ubicloud.com), running in the same Falkenstein region as the app. Ubicloud handles daily backups and 7-day point-in-time recovery. A weekly `pg_dump` is pushed to Cloudflare R2 for good measure.

## Background Jobs

Pagecord uses ActiveJob for background jobs, which are configured to use Sidekiq, which requires Redis.

### Cloudflare R2

Images are processed by ActiveStorage and stored on [Cloudflare R2](https://developers.cloudflare.com/r2/). Exports are stored on R2 as well.

### Hatchbox

Pagecord uses Hatchbox to manage deployments.

### Custom domains / SSL

Premium accounts can apply a custom domain to their blog. SSL certification is handled by [Caddy](https://caddyserver.com/).

### DNS & Edge Caching

DNS for Pagecord is managed by [Cloudflare](https://cloudflare.com). Cloudflare sits in front of the app, providing edge caching for `*.pagecord.com` blog pages. Custom domains route through Caddy and are not edge-cached by Cloudflare. The full picture is in [docs/sysadmin/cloudflare-edge-caching.md](docs/sysadmin/cloudflare-edge-caching.md).

### Email

Inbound emails are handled by [Postmark](https://postmarkapp.com) via ActionMailbox.

Transactional emails are sent via [Cloudflare Email](https://developers.cloudflare.com/email-routing/), [Postmark](https://postmarkapp.com), and [Mailpace](https://mailpace.com). Each has its own base mailer class (`CloudflareMailer`, `PostmarkMailer`, `MailpaceMailer`).

### Observability

Pagecord uses [Sentry](https://sentry.io) for logging errors and [AppSignal](https://appsignal.com) for observability. When something needs chasing in production, start with [docs/sysadmin/production-debugging-guide.md](docs/sysadmin/production-debugging-guide.md).
