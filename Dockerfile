# syntax = docker/dockerfile:1

ARG RUBY_VERSION=3.4.5
FROM ruby:$RUBY_VERSION-slim

WORKDIR /rails

ENV RAILS_ENV=development \
    BUNDLE_PATH=/usr/local/bundle \
    BUNDLE_JOBS=4 \
    BUNDLE_RETRY=3

# Install dependencies for building gems + running Rails
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
      build-essential \
      git \
      curl \
      postgresql-client \
      libvips \
      libyaml-dev \
      pkg-config \
      tzdata && \
    rm -rf /var/lib/apt/lists/*

# Copy Gemfile first to leverage Docker cache
COPY Gemfile Gemfile.lock .ruby-version ./

# Install gems
RUN bundle install

# Copy app source
COPY . .

EXPOSE 3000

# Default command: start bin/dev if it exists, else rails server
CMD ["sh", "-c", "if [ -f bin/dev ]; then exec bin/dev; else exec bin/rails server -b 0.0.0.0; fi"]
