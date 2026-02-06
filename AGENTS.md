# AGENTS.md

Ruby on Rails blogging app (Pagecord). Ruby, CSS, YAML, JavaScript.

## Principles

- **Vanilla Rails**: No services, commands, or interactors. Private methods in controllers, rich domain models, concerns for shared behavior. See [Vanilla Rails is Plenty](https://dev.37signals.com/vanilla-rails-is-plenty/).
- **Minimal code**: Fewer lines when clarity is maintained. Simple over clever. No over-engineering or premature abstraction.
- **Idiomatic**: Follow Ruby and Rails conventions throughout. Fat models, skinny controllers, RESTful routes.

## Code Style

- Double quotes for strings, not single quotes
- Remove trailing whitespace
- Private methods indented one additional level (2 spaces) after `private`
- Prefer ternary operators over case statements for 2-option logic
- Use `inline_svg_tag "icons/name.svg"` for SVGs — never hardcode `<svg>` elements
- Avoid N+1 queries: use `.includes()`, `.eager_load()`, or `.preload()`

## JavaScript & Frontend

- **Importmaps** only (NOT npm/yarn/webpack). Add packages: `bin/importmap pin package-name`
- **Stimulus only**: Never inline `<script>` tags or vanilla JS in views. No jQuery.
- Use Stimulus targets (not `querySelector`), actions (`data-action`), and values for data passing
- Prefer existing Stimulus components (e.g., `stimulus-sortable`) over custom implementations
- Use Turbo Frames and Streams for dynamic updates

## CSS & Styling

- **App views**: Tailwind utility classes with dark mode variants (`dark:bg-slate-800`, etc.)
- **Blog views**: Semantic CSS classes, NOT Tailwind. Layout: `layouts/blog.html.erb`. Typography uses `em` units for scaling.
- **Logical properties**: Prefer `margin-inline-start` over `margin-left` for RTL support
- Primary button color: `bg-[#4fbd9c]` (`btn-primary` class)

## Testing

- Minitest with fixtures. Follow Rails conventions for file location.
- Focused tests for business logic — don't over-test
- **System test gotchas**:
  - Flash messages are initially hidden; use `assert page.has_content?("Text", wait: 2)` not `assert_text`
  - Allow `sleep 1` after form submissions for async operations
  - Tests set `I18n.locale = :en` in setup to avoid parallel locale issues

## Git Commits

- No footers ("Generated with Claude Code", "Co-Authored-By", etc.)
- Ask for human review before committing generated code

## Tooling

- **Rubocop** auto-runs on every file edit/write via a PostToolUse hook (see `.claude/settings.json`)
- **CI skill** (`/ci`): runs brakeman, rubocop, importmap audit, and tests locally
- **Sentry skill** (`/sentry`): investigate and fix Sentry errors
- **Support skill** (`/support`): investigate customer issues and draft responses

## Commands

```bash
bin/dev                          # Start app (Rails, Tailwind, Redis, Sidekiq)
bin/rails test                   # Unit tests
bin/rails test:system            # System tests (not in Docker)
bin/system-test                  # System tests with Docker database
bundle exec rubocop              # Linter
bundle exec brakeman             # Security scanner
```

Docker: prefix commands with `docker-compose exec web`

## Architecture

- **Core models**: User has one Blog. Blog has many Posts (posts + pages via `is_page` flag), NavigationItems (STI: Page, Custom, Social), EmailSubscribers, Upvotes, Post::Replies, and SenderEmailAddresses
- **Auth**: Passwordless login via AccessRequest tokens (1-day expiry). EmailChangeRequest for email updates. Both use Verifiable concern.
- **Routing**: Constraint-based — pagecord.com for app/auth, subdomains and custom domains for blog content
- **Storage**: ActiveStorage on Cloudflare R2. Soft deletion with Discard gem. StorageTrackable concern tracks attachment bytes/count per blog.
- **Background**: Sidekiq + Redis. Cron via `whenever` gem (see `config/schedule.rb`)
- **External services**: Postmark + Mailpace (email, dual provider), Sentry (errors), AppSignal (observability), Hatchbox (hosting/custom domains), Paddle (billing)

### Billing & Access
- **Payments**: Paddle webhooks (`Billing::PaddleEventsController`) → Subscription model. Plans: monthly, annual, complimentary
- **Trial**: 14-day free trial. `has_premium_access?` = subscribed OR on trial. `subscribed?` = paid only.
- Trial-eligible features: analytics, image uploads, avatar, reply by email, upvotes, custom domains
- Subscriber-only features: email subscriptions, branding removal
- Payment failures handled automatically by Paddle Retain — don't email customers about failed payments

### Content Pipeline
- **Email-to-blog**: ActionMailbox → PostsMailbox → MailParser (HTML pipeline: body extraction → monospace detection → image unfurl → inline attachments → tag extraction → sanitize)
- **Content moderation**: OpenAI API via `ContentModerator`. `ContentModerationBatchJob` runs every 10 min. Flagged posts stay visible for admin review. Daily digest to admin via `ContentModerationDigestJob`.
- **Spam detection**: GPT-4o-mini via `SpamDetector`. Checks blogs 2h–7d old. Skips subscribers. Admin confirms (discards user) or dismisses. Daily digest via `SpamDetectionDigestJob`. IP reputation checks via `IpReputation` (ApiVoid, GetIpIntel providers).
- **Dynamic variables**: `{{ posts }}`, `{{ posts_by_year }}`, `{{ tags }}`, `{{ email_subscription }}` — processed in pages only (`is_page: true`) via `DynamicVariableProcessor`
- **OG images**: Auto-generated from first post image via `GenerateOpenGraphImageJob`

### Analytics
- PageView model (raw, recent) + Rollup model (aggregated, historical). Mixed data approach. Monthly rollup via `RollupAndCleanupPageViewsJob`.
- `Analytics::Base` (cutoff_time), `Analytics::Summary`, `Analytics::Chart`, `Analytics::Referrers`, `Analytics::Trending`, `Analytics::Leaderboard`, `Analytics::Countries`
- Privacy: visitor_hash (SHA256 of IP+UA+date), no raw IPs
- Referrer tracking with domain normalization, search/social classification via `Referrer` model

### Email Features
- **Post digests**: Weekly emails (Tuesdays) to confirmed EmailSubscribers. `PostDigest` → `PostDigest::DeliveryJob` → `PostDigest::PostmarkDelivery` (batches of 50). Requires `email_subscriptions_enabled` + `subscribed?`. Custom sender addresses via `SenderEmailAddress` (max 3 per blog, requires verification).
- **Reply by email**: `Post::Reply` model. Replies forwarded to blog owner via `ReplyMailer`. Digest replies handled by `DigestReplyMailer`.
- **Blog export**: HTML or Markdown ZIP via `BlogExportJob`. Auto-cleanup after 7 days. Rate limited to 5/day.

### Lifecycle Emails
- **Welcome**: `WelcomeMailer` on signup
- **Unengaged follow-up**: Monthly `SendUnengagedFollowUpEmailsJob` emails users with no posts after 1 month. Tracked by `UnengagedFollowUp` model (one per user).
- **Trial ended**: Daily `SendTrialEndedEmailsJob` notifies users when trial expires
- **Renewal reminders**: `Subscription::SendRenewalRemindersJob` emails annual subscribers 2 weeks before renewal
- **Cancellation**: `SendCancellationEmailJob` sends appropriate email (subscriber vs free account). User destruction via `DestroyUserJob`.

### Key Concerns
- **Subscribable**: Trial management (14 days), `has_premium_access?` vs `subscribed?`
- **Themeable**: 7 preset themes + custom, fonts, page widths, hex color validation
- **Sluggable**: URL slug generation with reserved words
- **Taggable**: Tag management with validation, normalization, querying
- **Verifiable**: Token-based verification with 24h expiry (used by email addresses, change requests)
- **CssSanitizable**: Custom CSS validation (4KB limit)

## Key Gotchas

- **ActionText before_save**: Read from `content.to_s` directly — ActionText changes aren't persisted until callback completes
- **Safari**: Doesn't support `*.localhost` — use Chrome/Firefox for subdomain testing
- **Blog views**: No Tailwind, use semantic CSS. Check `lexxy-typography.css`, `components.css`, `themes/*.css`
- **Post text_summary**: Cached plain text column updated via before_save. Use `display_title`, `summary(limit:)` — don't parse ActionText in loops
- **Analytics**: Uses mixed data (raw PageViews for recent, Rollups for historical). `cutoff_time` returns 1900-01-01 when no rollups exist to ensure raw data is always used.
