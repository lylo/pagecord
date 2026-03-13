# Cloudflare Edge Caching

Blog pages on `*.pagecord.com` subdomains are edge-cached by Cloudflare, purged automatically on post save or blog settings change.

## How it works

- Blog responses include `Cache-Tag: <blog-subdomain>` and `s-maxage=43200` (12 hours) in `Cache-Control`
- Cloudflare serves cached pages from its edge network without hitting the Rails app
- Browsers always revalidate (`max-age=0`) — they get instant responses from the edge, not from their local cache
- `stale-while-revalidate=3600` (1 hour) means Cloudflare can serve stale content while refreshing in the background
- When a post is saved or blog settings change, `PurgeCloudflareCacheJob` purges the cache by tag via the Cloudflare API
- One API call purges all cached pages for an entire blog (tag-based, not URL-based)
- The job retries automatically with polynomial backoff if the API call fails (e.g. rate limiting)
- Session cookies are skipped on cached pages, and CSRF verification is skipped on public blog form endpoints (upvotes, replies, email subscriptions) — these are protected by rate limiting, spam prevention, and encrypted form tokens instead
- Per-visitor state (upvote status, analytics) loads via async JS after the cached page renders

## Cache times

| Directive | Value | Meaning |
|-----------|-------|---------|
| `max-age` | 0 | Browsers always revalidate with Cloudflare |
| `s-maxage` | 43200 (12 hours) | Cloudflare edge cache TTL |
| `stale-while-revalidate` | 3600 (1 hour) | Serve stale while refreshing in background |

After a purge, the next request is a cache `MISS` (hits the Rails app), then subsequent requests are `HIT` (served from edge).

## Limitations

- **Custom domains** (e.g. `olly.world`) are not edge-cached — they route through Caddy, not the Cloudflare zone. They still benefit from ETags/304s and fragment caching.
- **Free plan rate limit** for cache purges is 5 requests/minute. The retry job handles this gracefully, but a burst of saves across many blogs could delay purges.

## Enabling

Edge caching is **off by default**. It activates when both env vars are set and `Rails.env.production?` is true. Without them, behaviour is unchanged.

### 1. Get your Zone ID

- Go to the [Cloudflare dashboard](https://dash.cloudflare.com)
- Select the pagecord.com domain
- Copy the **Zone ID** from the right sidebar on the Overview page

### 2. Create an API Token

- Go to **My Profile** (top-right avatar) > **API Tokens**
- Click **Create Token** > **Create Custom Token**
- Configure:
  - **Token name:** `Pagecord Cache Purge`
  - **Permissions:** Zone > Cache Purge > Purge
  - **Zone Resources:** Include > Specific zone > `pagecord.com`
- Click **Continue to summary** > **Create Token**
- Copy the token (only shown once)

### 3. Set env vars in Hatchbox

```
CLOUDFLARE_ZONE_ID=<your-zone-id>
CLOUDFLARE_API_TOKEN=<your-api-token>
```

### 4. Create a Cloudflare Cache Rule

Cloudflare does not cache HTML by default. A Cache Rule is required.

- Go to **Caching** > **Cache Rules** > **Create rule**
- **Rule name:** `Cache everything`
- **When:** All incoming requests
- **Then:** Cache eligibility > **Eligible for cache**
- Save and deploy

## Disabling

Remove or unset the env vars. The next request will stop sending `s-maxage` headers. Already-cached pages remain in Cloudflare's edge until their TTL expires (up to 12 hours). To clear immediately, use **Purge Everything** in the Cloudflare dashboard under Caching > Configuration.

## Verifying

```bash
# First request — MISS (not cached yet)
curl -sI https://olly.pagecord.com/another-test | grep -iE 'cache-control|cache-tag|cf-cache'

# Second request — HIT (served from edge)
curl -sI https://olly.pagecord.com/another-test | grep -iE 'cache-control|cache-tag|cf-cache'

# Expected:
# cache-control: public, max-age=0, s-maxage=43200, stale-while-revalidate=3600
# cache-tag: olly
# cf-cache-status: HIT
```

## Key files

- `app/controllers/blogs/posts_controller.rb` — sets `Cache-Tag`, `s-maxage` headers, skips session cookie
- `app/models/cloudflare_cache_api.rb` — Cloudflare API client for tag-based purging
- `app/jobs/purge_cloudflare_cache_job.rb` — async purge job with retry
- `app/models/post.rb` — `after_commit` triggers purge on post save
- `app/models/blog.rb` — `after_commit` triggers purge on blog settings change
