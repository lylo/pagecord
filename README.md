# Pagecord

A minimalist blogging app powered by email.

![](https://github.com/lylo/pagecord/actions/workflows/rails_tests.yml/badge.svg)

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
folder and create posts for the first user account in the seed data (`joel@meyerowitz.xyz`).

```bash
DIR=tmp/emails rake email:load
```

