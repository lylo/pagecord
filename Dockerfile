# syntax = docker/dockerfile:1

# Make sure RUBY_VERSION matches the Ruby version in .ruby-version and Gemfile
ARG RUBY_VERSION=4.0.10
FROM registry.docker.com/library/ruby:$RUBY_VERSION-slim AS base

# Rails app lives here
WORKDIR /rails

ENV BUNDLE_PATH="/usr/local/bundle"

# Install the packages the app runs with. pg_dump has to be at least as new as the production database.
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update -qq && \
    apt-get install --no-install-recommends -y ca-certificates curl ffmpeg libimage-exiftool-perl libjemalloc2 libvips poppler-utils postgresql-common && \
    /usr/share/postgresql-common/pgdg/apt.postgresql.org.sh -y && \
    apt-get install --no-install-recommends -y postgresql-client-18 && \
    ln -s /usr/lib/$(uname -m)-linux-gnu/libjemalloc.so.2 /usr/local/lib/libjemalloc.so

# Run as a non-root user for security
RUN useradd rails --uid 1000 --create-home --shell /bin/bash

ENTRYPOINT ["/rails/bin/docker-entrypoint"]
EXPOSE 3000
CMD ["./bin/rails", "server"]


# Adds the packages needed to build gems
FROM base AS build

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update -qq && \
    apt-get install --no-install-recommends -y build-essential git libyaml-dev libssl-dev pkg-config

COPY Gemfile Gemfile.lock .ruby-version ./
RUN gem install bundler -v "$(awk '/BUNDLED WITH/{getline; print $1}' Gemfile.lock)"


# Development stage, adds Chromium for system tests. docker-compose builds this.
FROM build AS dev

ENV RAILS_ENV="development"

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update -qq && \
    apt-get install --no-install-recommends -y chromium chromium-driver fonts-liberation

RUN bundle install && \
    bundle exec bootsnap precompile --gemfile

COPY . .
RUN chown -R rails:rails db log storage tmp
USER rails:rails


# Throw-away stage, so the final image has no build tools
FROM build AS release

ENV RAILS_ENV="production" \
    BUNDLE_DEPLOYMENT="1" \
    BUNDLE_WITHOUT="development:test"

RUN bundle install && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git && \
    bundle exec bootsnap precompile --gemfile

COPY . .
RUN bundle exec bootsnap precompile app/ lib/ && \
    SECRET_KEY_BASE_DUMMY=1 ./bin/rails assets:precompile


# The production image. Hatchbox builds the last stage, so keep it last.
FROM base AS app

ENV RAILS_ENV="production" \
    BUNDLE_DEPLOYMENT="1" \
    BUNDLE_WITHOUT="development:test" \
    LD_PRELOAD="/usr/local/lib/libjemalloc.so"

COPY --from=release /usr/local/bundle /usr/local/bundle
COPY --from=release /rails /rails

RUN chown -R rails:rails db log storage tmp
USER rails:rails
