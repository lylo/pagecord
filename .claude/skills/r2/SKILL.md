---
name: r2
description: Interact with Cloudflare R2 object storage - list objects, view stats, fetch files, and verify backup integrity. Usage: /r2 <command> [bucket] [args]
allowed-tools: Bash
---

# Cloudflare R2

Interact with Cloudflare R2 buckets via the Cloudflare API.

## Setup

Read credentials from `.env`:

```bash
grep '^CLOUDFLARE_' /Users/olly/dev/pagecord/.env
```

- **Account ID**: `CLOUDFLARE_ACCOUNT_ID`
- **Bucket tokens**: `CLOUDFLARE_R2_{BUCKET_ENV}` or `CLOUDFLARE_R2_{BUCKET_ENV}_READ_ONLY`

To map a bucket name to its env var: uppercase it and replace hyphens with underscores.
Example: `pagecord-wal-backups` → look for `CLOUDFLARE_R2_PAGECORD_WAL_BACKUPS` or `CLOUDFLARE_R2_PAGECORD_WAL_BACKUPS_READ_ONLY`.
Also try matching just a portion (e.g. `WAL_BACKUPS`) if the full name has a common prefix like `pagecord-`.

If only one bucket token is configured, use it automatically. If multiple, and no bucket is specified, list them and ask.

If `CLOUDFLARE_ACCOUNT_ID` is missing, stop and tell the user to add it to `.env`.

**Base API URL**: `https://api.cloudflare.com/client/v4/accounts/{ACCOUNT_ID}/r2/buckets/{BUCKET}`

All requests use `-H "Authorization: Bearer {TOKEN}"`.

Paginate object listings using the `cursor` from `result_info` when `is_truncated` is true. Always fetch all pages for check/inspect/stat commands.

---

## Commands

Usage: `/r2 <command> [bucket] [args]`

---

### `ls [bucket] [prefix]`

List objects in a bucket, optionally filtered by prefix.

```
GET /objects?per_page=1000&prefix={PREFIX}
```

Display as a table: key, size (human-readable), last modified. Show total count and total size at the bottom. Paginate if needed but limit display to first 100 rows; note if truncated for display only.

---

### `stat [bucket]`

Show a summary of the bucket. Fetch all pages.

Report:
- Total object count and total size
- Oldest and newest object (key + timestamp)
- If WAL-G structure detected (see below): number of base backups and WAL segment span

---

### `cat [bucket] [key]`

Fetch and display the contents of a single object.

```
GET /objects/{KEY}
```

Pretty-print if JSON. Warn if the object is large (> 100 KB) before fetching.

---

### `check [bucket]`

**Surface-level integrity check — does not fetch file contents, only inspects the object listing.**

1. Fetch all object keys (all pages).
2. Detect WAL-G structure: present if both `*/basebackups_005/` and `*/wal_005/` prefixes exist.

**If WAL-G structure detected:**

- **Base backups**: list all directories matching `*/basebackups_005/base_*/` (exclude sentinel files themselves)
- **Sentinels**: for each base backup dir, check that `{dir_name}_backup_stop_sentinel.json` exists
- **WAL segments**: extract all keys matching `*/wal_005/[0-9A-F]{24}.lz4` (standard 24-hex-char WAL names, no dots)
- **WAL gap check**: parse each WAL segment name as timeline (first 8 hex) + log (next 8 hex) + segment (last 8 hex). Sort and verify each segment is exactly one after the previous. When segment rolls from 0xFF → 0x00, log increments by 1.
- **WAL recency**: check how long ago the latest WAL segment was modified (warn if > 15 minutes)

**If no WAL-G structure:**
- Report object count, size, and age of most recently modified object.

**Output table:**

| Check | Status |
|-------|--------|
| Base backups found | ✅ N |
| All sentinels present | ✅ / ⚠️ missing: [...] |
| WAL segments | ✅ N segments |
| WAL continuity | ✅ No gaps / ⚠️ N gaps found |
| WAL recency | ✅ Latest N min ago / ⚠️ Last WAL is Xh old |

---

### `inspect [bucket]`

**Deep integrity check — fetches and parses backup metadata files.**

Run all `check` steps first (object listing analysis), then additionally:

1. For each base backup, fetch `_backup_stop_sentinel.json` and parse:
   - `StartTime`, `FinishTime`, `LSN`, `FinishLSN`, `PgVersion`, `Hostname`, `CompressedSize`, `UncompressedSize`, `IsPermanent`
2. Verify across all backups:
   - Each backup completed cleanly (`FinishTime` > `StartTime` and sentinel exists)
   - LSNs are monotonically increasing across backups
   - All backups share the same `PgVersion` and `Hostname`
   - `IsPermanent` flag noted (false means subject to WAL-G retention/expiry)
3. Verify WAL coverage: the latest WAL segment's log/seg position is ahead of the latest backup's `FinishLSN`

**Output: surface check table + backup detail table:**

| Backup | Started | Duration | Compressed | PG Version | LSN Range |
|--------|---------|----------|------------|------------|-----------|
| base_000...66 | 2026-03-18 03:00 UTC | 5s | 529 MB | 18.2 | 0x...→0x... |
| ... | | | | | |

Then a final verdict: ✅ All checks passed / ⚠️ Issues found: [list]

---

## Output Guidelines

- Show which bucket and token env var you're using at the start (mask the token value)
- Sizes: human-readable (KB, MB, GB)
- Timestamps: UTC
- For errors: show HTTP status and error body
- Keep output concise; don't dump raw API responses
