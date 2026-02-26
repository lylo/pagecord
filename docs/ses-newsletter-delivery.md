# SES Newsletter Delivery

Migrates outbound newsletter delivery from Postmark to Amazon SES for cost reduction (~10x cheaper at scale). Runs in parallel with Postmark during warm-up, feature-flagged per blog.

**Scope:** Outbound newsletters only. Postmark stays for Action Mailbox inbound (`newsletters.pagecord.com`). MailPace stays for transactional email. SES sends from `send.pagecord.com`.

## Architecture

```
Blog (feature flag: ses_newsletter_delivery)
  │
  ├── PostDigest::DeliveryJob
  │     ├── PostDigest::PostmarkDelivery  (default path)
  │     └── PostDigest::SesDelivery       (when flag enabled)
  │           ├── Filters out Email::Suppression addresses
  │           ├── Sends via Aws::SESV2::Client (per-message)
  │           ├── Creates PostDigestDelivery + Email::Event records
  │           └── Failover: eu-west-2 → eu-west-1
  │
  └── Email::ProcessBouncesJob (every 5 min)
        ├── Polls SQS queue (long poll, 5s)
        ├── Parses SNS → SES notification JSON
        ├── Permanent bounce → Email::Suppression + update Email::Event
        ├── Complaint → Email::Suppression + update Email::Event
        └── Transient bounce → ignored (logged)
```

## Data Model

### `email_suppressions`

Prevents future sends to bounced/complained addresses. The `EmailSubscriber` record stays intact — only the suppression list blocks delivery. Admins can unsuppress to retry.

| Column | Type | Description |
|--------|------|-------------|
| `email` | string | Downcased email address (unique index) |
| `reason` | string | `"bounce"` or `"complaint"` |
| `bounce_type` | string | `"Permanent"` / `"Transient"` (bounces only) |
| `diagnostic_code` | string | Raw SMTP diagnostic from the MTA |
| `suppressed_at` | datetime | When the suppression was recorded |

### `email_events`

Correlates SES message IDs back to specific deliveries for bounce processing.

| Column | Type | Description |
|--------|------|-------------|
| `message_id` | string | SES message ID (unique index) |
| `provider` | string | `"ses"` or `"postmark"` |
| `post_digest_delivery_id` | reference | FK to `post_digest_deliveries` |
| `status` | string | `"sent"`, `"delivered"`, `"bounced"`, `"complained"` |

## Feature Flag

The `ses_newsletter_delivery` flag is per-blog, stored in the `blogs.features` PG array column. Enable via Rails console:

```ruby
blog = Blog.find_by(subdomain: "yourblog")
blog.update!(features: blog.features + ["ses_newsletter_delivery"])
```

When enabled, `PostDigest::DeliveryJob` routes to `PostDigest::SesDelivery` instead of `PostDigest::PostmarkDelivery`. When disabled (or absent), Postmark is used as before.

## Environment Variables

Set these on Hatchbox before enabling the feature flag:

| Variable | Description |
|----------|-------------|
| `AWS_SES_ACCESS_KEY_ID` | IAM credentials for SES/SQS/SNS |
| `AWS_SES_SECRET_ACCESS_KEY` | IAM credentials for SES/SQS/SNS |
| `AWS_SES_REGION` | Primary region (default: `eu-west-2`) |
| `AWS_SES_BOUNCE_QUEUE_URL` | SQS queue URL for bounce notifications |
| `SES_MAX_SENDS_PER_SECOND` | Rate limit safety net (default: `14`) |

## Setup

### 1. Provision AWS Resources

```bash
rake ses:provision
```

This creates:
- SES domain identities in both regions (`send.pagecord.com`)
- SNS topics for bounce/complaint notifications in both regions
- SQS queue with DLQ in primary region
- SNS→SQS subscriptions (including cross-region for failover)
- SES configuration sets and event destinations

The task outputs DNS records and env vars to set manually.

### 2. Add DNS Records

The `ses:provision` task prints the exact records. Typically:

**DKIM** — 3 CNAME records (provided by SES):
```
<token1>._domainkey.send.pagecord.com CNAME <token1>.dkim.amazonses.com
<token2>._domainkey.send.pagecord.com CNAME <token2>.dkim.amazonses.com
<token3>._domainkey.send.pagecord.com CNAME <token3>.dkim.amazonses.com
```

**SPF:**
```
send.pagecord.com TXT "v=spf1 include:amazonses.com ~all"
```

**DMARC:**
```
_dmarc.send.pagecord.com TXT "v=DMARC1; p=none; rua=mailto:dmarc-reports@pagecord.com"
```

**Custom MAIL FROM:**
```
bounce.send.pagecord.com MX 10 feedback-smtp.eu-west-2.amazonses.com
bounce.send.pagecord.com TXT "v=spf1 include:amazonses.com ~all"
```

### 3. Verify Setup

```bash
rake ses:status
```

Check that the domain is verified, DKIM is signing, and production access is enabled.

### 4. Request Production Access

SES starts in sandbox mode (can only send to verified addresses). Request production access through the AWS console on day 1.

### 5. Enable on Test Blog

```ruby
blog = Blog.find_by(subdomain: "yourblog")
blog.update!(features: blog.features + ["ses_newsletter_delivery"])
```

### 6. Gradual Rollout

| Days | Blogs on SES | Notes |
|------|-------------|-------|
| 1-3 | Your own blog only | Verify delivery, headers, bounce simulator |
| 4-7 | ~10% of blogs | Monitor SES dashboard bounce/complaint rates |
| 8-10 | ~50% of blogs | |
| 11+ | All blogs | Stable — remove Postmark path later |

## Admin UI

Visit `/admin/suppressed_emails` to:
- View all suppressed emails with reason, bounce type, and diagnostic info
- Filter by bounces or complaints
- Unsuppress an email to allow future deliveries

## Key Files

| File | Purpose |
|------|---------|
| `app/models/email/suppression.rb` | Suppression list model |
| `app/models/email/event.rb` | Per-delivery event tracking |
| `app/models/post_digest/ses_delivery.rb` | SES delivery (mirrors PostmarkDelivery) |
| `app/jobs/post_digest/delivery_job.rb` | Dispatch job (feature flag branch) |
| `app/jobs/email/process_bounces_job.rb` | SQS polling for bounces/complaints |
| `app/controllers/admin/suppressed_emails_controller.rb` | Admin suppression management |
| `lib/tasks/ses.rake` | Provisioning and status rake tasks |
| `config/features.rb` | Feature flag definition |

## Troubleshooting

### Emails not sending via SES

1. **Check feature flag is enabled** for the blog:
   ```ruby
   blog.features.include?("ses_newsletter_delivery")
   # => true
   ```

2. **Check env vars are set:**
   ```ruby
   ENV["AWS_SES_ACCESS_KEY_ID"].present?
   ENV["AWS_SES_SECRET_ACCESS_KEY"].present?
   ENV["AWS_SES_REGION"].present?
   ```

3. **Check SES is out of sandbox:**
   ```bash
   rake ses:status
   # Look for "Production access: true"
   ```

4. **Check Sidekiq logs** for the `:newsletters` queue — look for `Aws::SESV2::Errors` messages.

### Bounces not being processed

1. **Check `AWS_SES_BOUNCE_QUEUE_URL` is set.** The job silently returns if this is nil.

2. **Check the SQS queue has messages:**
   ```ruby
   sqs = Aws::SQS::Client.new(region: ENV["AWS_SES_REGION"], credentials: Aws::Credentials.new(ENV["AWS_SES_ACCESS_KEY_ID"], ENV["AWS_SES_SECRET_ACCESS_KEY"]))
   attrs = sqs.get_queue_attributes(queue_url: ENV["AWS_SES_BOUNCE_QUEUE_URL"], attribute_names: ["ApproximateNumberOfMessages"])
   attrs.attributes["ApproximateNumberOfMessages"]
   ```

3. **Check the SNS→SQS subscription is confirmed.** Cross-region subscriptions require confirmation — verify in the AWS console under SNS > Subscriptions.

4. **Check the DLQ** (`pagecord-ses-bounces-dlq`) for messages that failed processing 5 times.

5. **Check Sidekiq logs** for the `:low` queue — the job runs every 5 minutes via cron.

### Subscriber still receiving emails after bounce

The `Email::Suppression` record must exist with a matching (downcased) email. Check:

```ruby
Email::Suppression.suppressed?("user@example.com")
```

If `false`, the bounce may have been transient (only permanent bounces create suppressions) or the `ProcessBouncesJob` hasn't run yet.

### SES region failover

`PostDigest::SesDelivery.deliver_with_failover` tries `eu-west-2` first. If it gets an `Aws::SESV2::Errors::ServiceError` or `Seahorse::Client::NetworkingError`, it retries the entire delivery with `eu-west-1`. Both regions need the domain identity verified and DNS records in place (the `ses:provision` task sets up both).

### Unsuppressing an email

Via admin UI: `/admin/suppressed_emails` → click "Unsuppress".

Via console:
```ruby
Email::Suppression.find_by(email: "user@example.com")&.destroy
```

This only removes the suppression — if the underlying issue isn't resolved (e.g., mailbox still doesn't exist), the address will be re-suppressed on the next bounce.

### Rate limiting

SES has account-level send rate limits (starts at 1/sec in sandbox, typically 14/sec in production). The `SES_MAX_SENDS_PER_SECOND` env var (default 14) throttles sends. If you see `Aws::SESV2::Errors::TooManyRequestsException`, lower this value.

At current volume (<5K newsletters), rate limiting won't activate.

### Testing with SES simulator addresses

SES provides simulator addresses that don't affect your bounce/complaint rates:

- `success@simulator.amazonses.com` — successful delivery
- `bounce@simulator.amazonses.com` — hard bounce
- `complaint@simulator.amazonses.com` — complaint

Use these during the warm-up phase to verify the full pipeline without affecting real addresses.
