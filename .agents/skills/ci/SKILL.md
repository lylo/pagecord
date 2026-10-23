---
name: ci
description: Run the local CI sequence for this repo. Use when the user asks to run CI, verify a branch before push, or check code quality with the full local pipeline.
allowed-tools: Bash
---

# CI

Run `bin/ci` (on Linux, `docker compose exec -T web bin/ci`). It runs every step in `config/ci.rb` and reports each one with its runtime. Pass `--fail-fast` to stop at the first failure.

Report a short status summary with one line per step. If a step fails, include the failing command and the key error.
