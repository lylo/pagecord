# Pagecord

A minimalist blogging app powered by email.

![](https://github.com/lylo/pagecord/actions/workflows/ci.yml/badge.svg)

## Development

To set up your development environment, install Ruby 3.3+ using [HomeBrew](https://brew.sh/) and [rbenv](https://github.com/rbenv/rbenv).

Then checkout this repository and run:

```bash
git clone https://github.com/lylo/pagecord.git
cd pagecord
bundle install
```

### Setting up the database

Before you run the app in development, first set up the database:

```bash
rails db:setup
```

### Install Redis

Pagecord uses Sidekiq, which uses Redis.

```
brew install redis
```

### Running the app

```bash
bin/dev
```

### Running the tests

The app is tested using the Rails standard, minitest. To run the tests, use the following commands:

```bash
bin/rails test
bin/rails test:system
```

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

Follow the [Pagecord blog](https://pagecord.com/pagecord).
