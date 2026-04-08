---
name: r2
description: Interact with Cloudflare R2 buckets used by Pagecord. Use when the user wants to list objects, inspect bucket stats, fetch files, or check backup integrity in R2.
---

# R2

Use the Cloudflare API for R2 buckets.

## Setup

- Read `CLOUDFLARE_ACCOUNT_ID` and the relevant bucket token from `/Users/olly/dev/pagecord/.env`.
- Bucket tokens follow `CLOUDFLARE_R2_{BUCKET}` or `CLOUDFLARE_R2_{BUCKET}_READ_ONLY`.
- Map bucket names by uppercasing and replacing hyphens with underscores.
- If more than one bucket token is configured and the user did not specify a bucket, list the candidates and ask.

Base API URL:

`https://api.cloudflare.com/client/v4/accounts/{ACCOUNT_ID}/r2/buckets/{BUCKET}`

## Common operations

- `ls`: list objects, optionally under a prefix
- `stat`: summarize object count, size, oldest/newest objects
- `cat`: fetch a single object, warning first for large objects
- `check`: surface-level backup integrity check from listings
- `inspect`: deeper backup integrity check including sentinel metadata

Paginate listings until exhausted. Keep output concise and human-readable.
