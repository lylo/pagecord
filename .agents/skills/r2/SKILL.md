---
name: r2
description: Interact with Cloudflare R2 buckets used by Pagecord. Use when the user wants to list objects, inspect bucket stats, fetch files, or check backup integrity in R2.
allowed-tools: Bash
---

# R2

Use the Cloudflare API for R2 buckets.

## Setup

- Read `CLOUDFLARE_ACCOUNT_ID` and the relevant bucket token from `/Users/olly/dev/pagecord/.env`.
- Bucket tokens follow `CLOUDFLARE_R2_{BUCKET}` or `CLOUDFLARE_R2_{BUCKET}_READ_ONLY`.
- Map bucket names by uppercasing and replacing hyphens with underscores.
- Also try matching just a distinctive suffix, such as `WAL_BACKUPS`, if the full name has a common prefix like `pagecord-`.
- If `CLOUDFLARE_ACCOUNT_ID` is missing, stop and say so.
- If more than one bucket token is configured and the user did not specify a bucket, list the candidates and ask.

Base API URL:

`https://api.cloudflare.com/client/v4/accounts/{ACCOUNT_ID}/r2/buckets/{BUCKET}`

All requests use `Authorization: Bearer {TOKEN}`. Show the bucket and token env var in use, but never print the raw token.

Paginate object listings using the `cursor` from `result_info` when `is_truncated` is true. Always fetch all pages for `check`, `inspect`, and `stat`.

## Commands

### `ls [bucket] [prefix]`

List objects in a bucket, optionally filtered by prefix, using `GET /objects?per_page=1000&prefix={PREFIX}`. Display key, human-readable size, and last modified date. Show total count and total size. Limit display to the first 100 rows and say when display is truncated.

### `stat [bucket]`

Fetch all pages and report total object count, total size, oldest object, newest object, and WAL-G structure if detected.

### `cat [bucket] [key]`

Fetch one object with `GET /objects/{KEY}`. Pretty-print JSON. Warn before fetching objects larger than 100 KB when the size is known.

### `check [bucket]`

Surface-level backup integrity check from object listings only:

1. Fetch all object keys.
2. Detect WAL-G structure when both `*/basebackups_005/` and `*/wal_005/` prefixes exist.
3. For WAL-G, list base backup directories matching `*/basebackups_005/base_*/`.
4. Verify each base backup has a `{dir_name}_backup_stop_sentinel.json`.
5. Extract WAL segments matching `*/wal_005/[0-9A-F]{24}.lz4`.
6. Sort WAL segments by timeline, log, and segment; verify continuity, including segment rollover from `0xFF` to `0x00` with log increment.
7. Check WAL recency and warn if the latest segment is older than 15 minutes.

If no WAL-G structure is detected, report object count, size, and age of the newest object.

### `inspect [bucket]`

Deep backup integrity check:

1. Run all `check` steps first.
2. Fetch and parse each `_backup_stop_sentinel.json`.
3. Inspect `StartTime`, `FinishTime`, `LSN`, `FinishLSN`, `PgVersion`, `Hostname`, `CompressedSize`, `UncompressedSize`, and `IsPermanent`.
4. Verify backups completed cleanly, LSNs are monotonic, `PgVersion` and `Hostname` are consistent, and the latest WAL segment is ahead of the latest backup `FinishLSN`.

## Output

- Use concise tables for listings and checks.
- Sizes should be human-readable.
- Timestamps should be UTC.
- For errors, show the HTTP status and response body.
- Keep raw API responses out of the final answer unless requested.
