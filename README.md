# Pagecord

Publish your writing effortlessly. All you need is email.

[https://pagecord.com](https://pagecord.com)

![](https://github.com/lylo/pagecord/actions/workflows/ci.yml/badge.svg)

## Development

### Quick Start with Docker

The easiest way to get Pagecord running locally is with Docker.

First, install [Docker Desktop](https://www.docker.com/products/docker-desktop/) and make sure it's running.

Then:

```bash
git clone https://github.com/lylo/pagecord.git
cd pagecord
docker-compose up
```

This will:
- Start PostgreSQL, Redis, and Memcached containers
- Build and run the Rails app
- Set up the database automatically

You can view the app at [http://localhost:3000](http://localhost:3000). It's configured to use `lvh.me`, so you can view individual blogs on their respective subdomains, e.g. [http://joel.lvh.me:3000](http://joel.lvh.me:3000).

### Running commands in Docker

```bash
# Rails console
docker-compose exec web bin/rails console

# Run tests
docker-compose exec web bin/rails test
docker-compose exec web bin/rails test:system

# Run migrations
docker-compose exec web bin/rails db:migrate

# Process emails (debug)
docker-compose exec web bash -c "DIR=tmp/emails rake email:load"
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

## More info

Read about [the Pagecord architecture](architecture.md) or [making contributions](CONTRIBUTIONS.md).

Follow the [Pagecord blog](https://pagecord.com/blog).

<a href="https://www.buymeacoffee.com/heyolly" target="_blank"><img src="https://cdn.buymeacoffee.com/buttons/v2/default-red.png" alt="Buy Me A Coffee" style="height: 50px !important;width: 178px !important;" ></a>