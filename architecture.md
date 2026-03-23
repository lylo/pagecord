# Pagecord Architecture

Pagecord is a minimal blogging app where you create posts simply by sending emails. It's a Rails app hosted on a single Hetzner instance via [Hatchbox](https://hatchbox.io). This is not super-scalable, but it's currently a side project so 🤷‍♂️

## Web app

Pagecord is a web app that uses [Rails](https://rubyonrails.org) 8 and associated tech like Turbo, Stimulus and Import Maps. It uses [Tailwind CSS](https://tailwindcss.com) for styling. It runs on Ruby 3.4.7.

## Database

Currently the database is Postgres which runs on a Hetzner server, thanks to Hatchbox. It's not a managed service, but WAL files are continuously replicated to Cloudflare R2 via WAL-G, enabling point-in-time recovery.

## Background Jobs

Pagecord uses ActiveJob for background jobs, which are configured to use Sidekiq, which requires Redis. I'll probably move this to SolidQueue at some point.

### Cloudflare R2

Images are processed by ActiveStorage and stored on [Cloudflare R2](https://developers.cloudflare.com/r2/). Exports are stored on R2 as well.

### Hatchbox

Pagecord uses Hatchbox to manage deployments. Everything runs on a single Hetzner server. As Pagecord makes more profit, I might move the app to DigitalOcean droplets and use a managed database.

### Custom domains / SSL

Premium accounts can apply a custom domain to their blog. Pagecord does this by using the Hatchbox API. Internally, Hatchbox uses [Caddy](https://caddyserver.com/).

Ideally I would run a separate server and create a reverse proxy using Caddy, detaching custom domains from the underlying app hosting. I'm avoiding the overhead of hosting costs and sysadmin work, but it'll bite me at some point I know.

### DNS & Edge Caching

DNS for Pagecord is managed by [Cloudflare](https://cloudflare.com). Cloudflare sits in front of the app, providing edge caching for `*.pagecord.com` blog pages. Custom domains route through Caddy and are not edge-cached by Cloudflare.

### Email

Inbound emails are handled by [Postmark](https://postmarkapp.com) via ActionMailbox.

Transactional emails are sent via a mixture of [Postmark](https://postmarkapp.com) and [Mailpace](https://mailpace.com).

### Observability

Pagecord uses [Sentry](https://sentry.io) for logging errors and [AppSignal](https://appsignal.com) for observability.
