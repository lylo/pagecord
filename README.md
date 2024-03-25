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

Sometimes you'll need to debug an email. Get the raw email source and save it to a .eml file.

Edit the .eml file so that the `To:` and `From:` fields match a user in the database, e.g.

```
From: joel@meyerowitz.xyz
To: joel_gf35jsue@post.pagecord.com
```

You can then run the following command:

```bash
  FILE=/path/to/your/file.eml rake email:load
```

