# Pagecord Architecture

Pagecord is a fully featured personal website and blogging app. It's a Rails app hosted by Hetzner, in Falkenstein, Germany.

## Web app

Pagecord is a web app that uses [Rails](https://rubyonrails.org) 8 and associated tech like Turbo, Stimulus and Import Maps. It runs on Ruby 4.0.5. It uses Memcached for caching.

## Database

The database is managed Postgres 18 on [Ubicloud](https://www.ubicloud.com), running in the same Falkenstein region as the app. Ubicloud handles daily backups and 7-day point-in-time recovery.A weekly `pg_dump` is pushed to Cloudflare R2 for good measure.

## Background Jobs

Pagecord uses ActiveJob for background jobs, which are configured to use Sidekiq, which requires Redis.

### Cloudflare R2

Images are processed by ActiveStorage and stored on [Cloudflare R2](https://developers.cloudflare.com/r2/). Exports are stored on R2 as well.

### Hatchbox

Pagecord uses Hatchbox to manage deployments.

### Custom domains / SSL

Premium accounts can apply a custom domain to their blog. SSL certification is handled by [Caddy](https://caddyserver.com/).

### DNS & Edge Caching

DNS for Pagecord is managed by [Cloudflare](https://cloudflare.com). Cloudflare sits in front of the app, providing edge caching for `*.pagecord.com` blog pages. Custom domains route through Caddy and are not edge-cached by Cloudflare.

### Email

Inbound emails are handled by [Postmark](https://postmarkapp.com) via ActionMailbox.

Transactional emails are sent via [Cloudflare Email](https://developers.cloudflare.com/email-routing/), [Postmark](https://postmarkapp.com), and [Mailpace](https://mailpace.com). Each has its own base mailer class (`CloudflareMailer`, `PostmarkMailer`, `MailpaceMailer`).

### Observability

Pagecord uses [Sentry](https://sentry.io) for logging errors and [AppSignal](https://appsignal.com) for observability.
