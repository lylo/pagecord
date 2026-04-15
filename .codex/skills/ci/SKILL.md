---
name: ci
description: Run the local CI sequence for this repo. Use when the user asks to run CI, verify a branch before push, or check code quality with the full local pipeline.
---

# CI

Run the local checks in this order and stop on first failure unless the user asks otherwise:

1. `bundle exec brakeman --quiet --no-pager --ensure-latest`
2. `bundle exec rubocop`
3. `bin/importmap audit`
4. `bin/rails test`
5. `bin/rails test:system`

Report a short status summary with one line per step. If a step fails, include the failing command and the key error.
