# Pagecord Architecture

Pagecord is a minimal blogging app where you create posts simply by sending emails. It's a Rails app hosted on a single Hetzner instance via [Hatchbox](https://hatchbox.io). This is not super-scalable, but it's currently a side project so 🤷‍♂️

## Web app

Pagecord is a basic web app that uses [Rails](https://rubyonrails.org) 8 and associated tech like Turbo, Stimulus and Import Maps. It uses [Tailwind CSS](https://tailwindcss.com) for styling. It runs on Ruby 3.3.4.

## Database

Currently the database is Postgres which runs on the EC2 server, thanks to Hatchbox. It's not a managed service, but it is backed up to Cloudflare R2 every 30 mins. Could be better, obvs.

## Background Jobs

Pagecord uses ActiveJob for background jobs, which are configured to use Sidekiq, which requires Redis. I'll probably move this to SolidQueue at some point.

### Cloudflare R2

Premium accounts can attach images to their emails. These are processed by ActiveStorage and stored on [Cloudflare R2](https://developers.cloudflare.com/r2/).

### Hatchbox

Pagecord uses Hatchbox to manage deployments. Everything runs on a single EC2 server. If Pagecord made a profit, I would still use Hatchbox but I'd move the app to DigitalOcean droplets (maybe even the app platform) and use a managed database.

### Custom domains / SSL

Premium accounts can apply a custom domain to their blog. Pagecord does this by using the Hatchbox API. Internally, Hatchbox uses [Caddy](https://caddyserver.com/).

Ideally I would run a separate server and create a reverse proxy using Caddy, detaching custom domains from the underlying app hosting. I'm avoiding the overhead of hosting costs and sysadmin work, but it'll bite me at some point I know.

### DNS

DNS for Pagecord is managed by [Cloudflare](https://cloudflare.com).

### Email

Inbound emails are managed by [Postmark](https://postmarkapp.com). The Pagecord app uses ActionMailbox to receive and process the emails.

### Observability

Pagecord uses Sentry for logging errors. There's no other monitoring right now because budgets 😱
