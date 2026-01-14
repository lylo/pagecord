---
name: ci
description: Run the CI pipeline locally (brakeman, rubocop, importmap audit, tests). Use when asked to run CI, check code quality, or verify code before pushing.
---

# CI

Run the CI pipeline locally before pushing.

## Steps

Run these commands in sequence, stopping on first failure:

1. **Brakeman** (security scan)
   ```bash
   bundle exec brakeman --quiet --no-pager
   ```

2. **Rubocop** (style check)
   ```bash
   bundle exec rubocop
   ```

3. **Importmap Audit** (JS dependency check)
   ```bash
   bin/importmap audit
   ```

4. **Unit Tests**
   ```bash
   bin/rails test
   ```

5. **System Tests**
   ```bash
   bin/rails test:system
   ```

## Behavior

- Run all checks in sequence
- Stop and report on first failure
- Summarize results at the end
- If all pass, confirm the code is ready to push
