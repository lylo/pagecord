# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Code Style & Conventions

**IMPORTANT**: When writing code for this project, always follow these principles:

### Ruby & Rails Style
- **Idiomatic Ruby**: Use Ruby conventions (`.map`, `.select`, `.find`, `&:method_name` shorthand, etc.)
- **Idiomatic Rails**: Follow Rails conventions (fat models, skinny controllers, RESTful routes, concerns for shared behavior)
- **Vanilla Rails**: No services, commands, or interactors - use private methods in controllers and rich domain models. See [Vanilla Rails is Plenty](https://dev.37signals.com/vanilla-rails-is-plenty/)
- **Minimal code**: Prefer fewer lines when clarity is maintained - Ruby's expressiveness is a feature
- **Elegant solutions**: Choose simple, readable solutions over complex ones
- **ActiveRecord patterns**: Use scopes, associations, validations, and callbacks appropriately
- **No over-engineering**: Avoid premature abstraction or unnecessary complexity
- **Private methods**: Indent private methods one additional level (2 spaces) after the `private` keyword per Rails conventions

### JavaScript & Frontend
- **Importmaps**: This project uses importmaps (NOT npm/yarn/webpack). Add packages with `bin/importmap pin package-name`
- **Stimulus controllers**: ALWAYS use Stimulus for JavaScript - NEVER use inline `<script>` tags or vanilla JS in views
- **Controller naming**: Use descriptive names like `navigation_form_controller.js`, `social_links_controller.js`
- **Stimulus components**: Prefer existing Stimulus components (e.g., `stimulus-sortable`) over custom implementations
- **Stimulus targets**: Use targets instead of `querySelector`
- **Stimulus actions**: Use `data-action` for event handling
- **Stimulus values**: Use values for passing data to controllers
- **No jQuery**: This is a modern Rails app using Hotwire/Stimulus
- **Turbo**: Leverage Turbo Frames and Streams for dynamic updates when appropriate

### Testing
- **Not over-tested**: Write focused tests for business logic, validations, and key methods
- **Fixtures**: Use fixtures for test data (already set up)
- **Minitest**: Use Minitest assertions (not RSpec)
- **Test file location**: Follow Rails conventions (`test/models/`, `test/controllers/`, etc.)

### CSS & Styling
- **Tailwind CSS**: Use Tailwind utility classes for styling
- **Existing patterns**: Check existing components before creating new styles
- **Primary color**: Use `bg-[#4fbd9c]` for primary buttons (see `btn-primary` class)
- **Dark mode**: Always include dark mode variants (`dark:bg-slate-800`, etc.)

### SVG Icons
- **Always use `inline_svg_tag`**: Never hardcode `<svg>` elements in views - use `inline_svg_tag "icons/name.svg"`
- **Icon location**: Store SVGs in `app/assets/images/icons/` (with `social/` subdirectory for social icons)
- **currentColor**: All icons should use `fill="currentColor"` or `stroke="currentColor"` to inherit text color
- **Exceptions**: Dynamically generated SVGs (e.g., analytics charts) may use inline markup

### Performance
- **Avoid N+1 queries**: Use `.includes()`, `.eager_load()`, or `.preload()` when loading associations
- **Caching**: Leverage Rails fragment caching and Russian Doll caching patterns
- **Database indexes**: Add indexes for foreign keys and frequently queried columns
- **Query optimization**: Use `.select()` to limit columns, `.pluck()` for single values

### Git Commits
- **No footers**: Do NOT add "Generated with Claude Code" or "Co-Authored-By" lines to commits
- **Concise messages**: Write clear, descriptive commit messages without unnecessary metadata

### Code Review Checklist
Before considering a feature complete, verify:
- [ ] No inline JavaScript (all in Stimulus controllers)
- [ ] Idiomatic Ruby/Rails patterns used
- [ ] Tests written and passing
- [ ] N+1 queries avoided
- [ ] Dark mode styles included
- [ ] Documentation added to CLAUDE.md (if significant feature)

## Development Commands

### Docker Setup (Preferred)
```bash
docker-compose up                    # Start all services (Rails, PostgreSQL, Redis, Memcached)
docker-compose up -d                 # Start in background
docker-compose down                  # Stop and remove containers
docker-compose exec web COMMAND     # Run command in running container
docker-compose run web COMMAND      # Run command in new container (if containers not running)
```

### Docker Development Commands
```bash
docker-compose exec web bin/rails console
docker-compose exec web bin/rails test
docker-compose exec web bin/rails test:system
docker-compose exec web bin/rails db:migrate
docker-compose exec web bundle exec rubocop
docker-compose exec web bundle exec brakeman
```

### Native Setup (Alternative)
```bash
bundle install
rails db:setup
brew install redis
```

### Running the app
```bash
bin/dev  # Starts Rails, Tailwind CSS watcher, Redis, and Sidekiq
```

### Testing
```bash
bin/rails test        # Run unit tests
bin/rails test:system # Run system tests (won't work in Docker - browser issues)

# System tests with Docker database (run on host):
bin/system-test
```

#### Writing System Tests
System tests can be unreliable due to timing issues. Here are key patterns to avoid flakiness:

**Flash Messages**: Flash messages are initially hidden and shown via JavaScript. Wait for them to become visible:
```ruby
# ❌ Flaky - may find hidden text
assert_text "Settings updated"

# ✅ Reliable - waits for visible content
assert page.has_content?("Settings updated", wait: 2)
```

**Form Submissions**: Allow time for async operations after clicking submit buttons:
```ruby
click_on "Create account"
sleep 1  # Allow form submission to complete
user = User.find_by(email: "test@example.com")
```

**Parallel Test Locale Issues**: Tests may run in different locales causing translation errors. The test helper ensures English locale for all tests with `I18n.locale = :en` in setup.

### Linting and Code Quality
```bash
bin/rails db:migrate  # Run database migrations
bundle exec rubocop   # Ruby style checker (Rails omakase)
bundle exec brakeman  # Security vulnerability scanner
```

### Email Processing (Development)
```bash
DIR=tmp/emails rake email:load  # Process .eml files for debugging
```

### Analytics (Development)
```bash
rake analytics:generate_sample_data BLOG=joel                    # Generate sample pageview data
rake analytics:generate_sample_data BLOG=joel ROLLUP=true        # Generate data + create rollups
RollupAndCleanupPageViewsJob.perform_now                         # Manually run rollup job
```

## Code Architecture

### Core Models
- **User**: Has one blog, includes authentication and subscription management
- **Blog**: Belongs to user, has many posts/pages, navigation_items, handles custom domains and theming
- **Post**: Blog content with rich text, attachments, and scheduling. Includes both posts and pages (is_page flag)
- **NavigationItem**: Unified navigation system (STI) with three types: PageNavigationItem, CustomNavigationItem, and SocialNavigationItem
- **Email processing**: Uses ActionMailbox with PostsMailbox to create posts from emails

### Key Features
- **Content Moderation**: Automated post moderation using OpenAI.
    - **Models**: `ContentModeration` (stores results), `ContentModerator` (service class), `Post::Moderatable` (concern).
    - **Flow**: `ContentModerationBatchJob` runs every 10 minutes, finds posts needing moderation, enqueues `ContentModerationJob` for each.
    - **API**: OpenAI moderation API allows 1 image per request, so `ContentModerator` makes separate calls for text and each image (up to 5), then aggregates results.
    - **Actions**: Flagged posts remain visible for admin review. Daily digest email with flagged post count.
    - **Admin**: `Admin::Moderation::ContentController` for reviewing flagged content (dismiss or discard).
- **Spam Detection**: New blog screening using GPT-4o-mini.
    - **Models**: `SpamDetection` (stores results), `SpamDetector` (service class).
    - **Flow**: `SpamDetectionJob` (daily) finds blogs 2 hours to 7 days old without existing check -> `SpamDetectionCheckJob` -> GPT-4o-mini -> Flags spam/uncertain.
    - **Timing**: Waits 2+ hours after blog creation so spammers have time to reveal themselves.
    - **Skips**: Subscribed users are not checked.
    - **Admin**: `Admin::Moderation::SpamController` for reviewing spam detections (confirm discards user, dismiss clears flag).
- **Post Digest Emails**: Weekly digest emails sent to blog subscribers with new posts.
    - **Models**:
      - `PostDigest` - Represents a digest (belongs to blog, has many posts via DigestPost, has many deliveries)
      - `DigestPost` - Join table linking digests to posts
      - `PostDigestDelivery` - Tracks which subscribers received a digest
      - `EmailSubscriber` - Blog subscribers (must be confirmed to receive digests)
    - **Delivery classes** (namespaced under `PostDigest::`):
      - `PostDigest::DeliveryJob` - Background job that triggers delivery
      - `PostDigest::PostmarkDelivery` - Handles batch sending via Postmark API (50 emails per batch)
    - **Flow**:
      1. `GeneratePostDigestsJob` (weekly) calls `PostDigest.generate_for(blog)` for each eligible blog
      2. `PostDigest.generate_for` finds new posts since last digest, creates digest with associated posts
      3. `PostDigest#deliver` enqueues `PostDigest::DeliveryJob` and marks digest as delivered
      4. `PostDigest::PostmarkDelivery#deliver_all` sends emails in batches, creates delivery records
    - **Eligibility**: Blog must have `email_subscriptions_enabled` and user must be `subscribed?`
    - **Resumable**: If delivery fails partway, pending subscribers are calculated by excluding those with existing deliveries
    - **Mailer**: `PostDigestMailer#weekly_digest` renders the email with Premailer CSS inlining
- **Email-to-blog**: Primary posting method via email (ActionMailbox)
- **Custom domains**: Premium feature using Hatchbox API
- **Rich text**: Uses ActionText for post content
- **Background jobs**: Sidekiq for async processing (email handling, image generation)
- **Subscriptions**: Paddle integration for payments
- **Multi-tenancy**: Blog subdomains (e.g., joel.pagecord.com)

### Domain Routing
- Default domain (pagecord.com): Marketing site, auth, app routes
- Custom/subdomain blogs: Blog-specific content and RSS feeds
- Constraint-based routing separates main app from blog content

### Storage & External Services
- **ActiveStorage**: Images on Cloudflare R2
- **Email**: Resend (inbound/outbound)
- **Monitoring**: Sentry (errors), AppSignal (observability)
- **Hosting**: Single Hetzner server via Hatchbox

### Testing
- Minitest framework
- System tests with Capybara/Selenium
- Email samples in test/email_samples/
- Fixtures for test data

### Database
- PostgreSQL with standard Rails migrations
- Key tables: users, blogs, posts, navigation_items, social_links, subscriptions, email_subscribers, page_views, rollups
- Soft deletion with Discard gem

#### Post Model Performance
- **text_summary column**: Cached plain text extracted from ActionText content
- **Purpose**: Eliminates N+1 queries when rendering post lists (archive pages, liquid tags, etc.)
- **Updated via `before_save` callback**: Parses content on every save to populate `text_summary`
- **Key methods**:
  - `display_title`: Returns title if present, otherwise truncated `text_summary` (64 chars), falls back to "Untitled" or "Home Page"
  - `summary(limit:)`: Returns truncated `text_summary` for any limit (used for meta descriptions, card previews, exports)
  - `has_text_content?`: Checks if `text_summary` is present
- **Important**: `text_content` method (private) has no memoization - always parses `content.to_s` fresh. Used only internally by callback.
- **ActionText gotcha**: In `before_save`, must read from `content.to_s` directly, not memoized helpers, because ActionText content changes aren't persisted until the callback completes

### Analytics System
- **PageView model**: Tracks individual page views with visitor_hash for uniqueness detection
- **Rollup model**: Aggregated analytics data using the `rollups` gem for performance
- **Mixed data approach**: Uses raw PageViews for recent data, Rollups for historical data
- **Analytics::Base**: Core class with `cutoff_time` logic (uses rollups when they exist, raw data otherwise)
- **Analytics::Summary**: Handles summary metrics with automatic data source selection
- **Analytics::Chart**: Generates chart data, supports month/year views with mixed data sources
- **RollupAndCleanupPageViewsJob**: Monthly job (1st at 1:30 AM) that creates rollups and deletes old PageViews
- **Privacy-focused**: Only stores visitor_hash (SHA256 of IP+UA+date), no raw IP addresses

### Billing & Subscriptions (Paddle)
- **Payment provider**: Paddle (handles payments, tax, invoicing)
- **Controller**: `Billing::PaddleEventsController` receives webhooks from Paddle
- **Model**: `Subscription` stores paddle_subscription_id, paddle_customer_id, paddle_price_id, unit_price, next_billed_at, cancelled_at, plan
- **Plans**: `plan` column enum with values: `monthly`, `annual`, `complimentary`
- **Price IDs**: Stored in `SubscriptionsHelper::PRICE_IDS` hash (keyed by plan and environment)
- **Webhook events handled**:
  - `subscription.created` - Creates/updates subscription record with plan detection
  - `subscription.updated` - Updates billing info, plan, handles scheduled cancellations
  - `subscription.canceled` - Marks subscription as cancelled
  - `subscription.past_due` - Logged only (Paddle handles recovery)
  - `transaction.completed` - Updates next_billed_at, unit_price, and plan (for plan changes)
  - `transaction.payment_failed` - Logged only (Paddle Retain handles recovery)
- **Plan switching**:
  - Monthly → Annual: Allowed via `change_plan` action, uses `PaddleApi#update_subscription_items` with prorated billing
  - Annual → Monthly: Not supported in UI (users must cancel, let subscription lapse, then resubscribe)
- **Resume subscription**: Cancelled subscriptions can be resumed via `PaddleApi#resume_subscription` (sets `scheduled_change: null`)
- **Subscription states in UI**:
  - Active monthly: Shows current plan card + "Switch to Annual" upgrade option
  - Active annual: Shows billing summary only (no downgrade option)
  - Cancelled: Shows "Resume Subscription" button
  - Lapsed: Shows both plan cards to resubscribe via Paddle checkout
- **Payment failure handling**: Paddle Retain automatically:
  - Retries failed payments up to 7 times over 30 days
  - Sends up to 4 recovery emails to customers (white-labeled)
  - Pauses or cancels subscription after recovery period (configurable in Paddle dashboard)
- **No manual intervention needed**: Don't email customers about failed payments - Paddle handles all dunning
- **Event logging**: All webhook events stored in `PaddleEvent` model for debugging
- **Signature verification**: HMAC-SHA256 verification of webhook payloads

### Free Trial System
- **Duration**: 14 days from account creation (configured in `Subscribable::TRIAL_PERIOD_DAYS`)
- **Concern**: `Subscribable` module in `app/models/concerns/subscribable.rb`
- **Key methods**:
  - `subscribed?` - Has active paid subscription (subscriber-only features)
  - `on_trial?` - Within 14-day trial period and not subscribed
  - `has_premium_access?` - Subscribed OR on trial (trial-eligible features)
  - `on_free_plan?` - Not subscribed AND not on trial (no premium access)
  - `trial_days_remaining` - Days left in trial (0 if not on trial)
- **Feature tiers**:
  - **Trial-eligible** (use `has_premium_access?`): Analytics, image uploads, avatar, reply by email, upvotes, custom domains
  - **Subscriber-only** (use `subscribed?`): Email subscriptions, branding removal
- **Trial ended email**: `FreeTrialMailer#trial_ended` sent via `SendTrialEndedEmailsJob` (daily at 5:15 AM)
- **Helper**: `trial_callout(feature_name)` in AppHelper shows upgrade prompt during trial

### Background Processing
- Sidekiq for async jobs
- Jobs: email processing, image generation, subscription handling, analytics rollups
- Redis required for job queue

## Development Notes

### Local Development
- Uses localhost for local subdomain testing (e.g. joel.localhost:3000)
- Note: Safari doesn't support *.localhost - use Chrome/Firefox for subdomain testing
- Redis must be running for background jobs

### Email Testing
- Letter opener for development email preview
- Can process saved .eml files for debugging (`DIR=tmp/emails rake email:load`)
- ActionMailbox handles inbound email parsing

### Email Parsing (MailParser)
- **Location**: `app/models/mail_parser.rb` (~180 lines)
- **Purpose**: Parses inbound emails into structured content (subject, body, attachments, tags)
- **Strategy**: Relies on the Mail gem's `html_part` and `text_part` methods for MIME handling
- **Apple Mail edge case**: Handles RFC violation where Apple Mail nests `multipart/mixed` (with multiple HTML fragments) inside `multipart/alternative` when users insert inline images between paragraphs
  - Affects ~6% of emails from Apple Mail users
  - Documented Apple Mail bug since at least 2010
  - Workaround extracts body content from each HTML fragment and joins them (10 lines in `collect_html_content` method)
- **Test coverage**: 14 tests covering multipart structures, attachments, edge cases
  - Test fixtures in `test/fixtures/emails/`
  - Tests include: multipart/alternative, Apple Mail edge case, inline images, attachments, empty emails
- **Key methods**:
  - `parse_body`: Main parsing logic, delegates to Mail gem for MIME handling
  - `collect_html_content`: Handles Apple Mail edge case
  - `html_transform`/`plain_text_transform`: Pipeline-based content transformation
  - Tag extraction via `Html::ExtractTags` pipeline step
- **Attachment handling**: Uses `process_unreferenced_attachments` to append attachments not referenced by Content-Id
- **Pipeline transformations** (applied in order):
  1. `Html::BodyExtraction` - Extracts `<body>` content
  2. `Html::MonospaceDetection` - Detects code blocks
  3. `Html::ImageUnfurl` - Processes image URLs
  4. `Html::InlineAttachments` - Handles Content-Id references
  5. `Html::ExtractTags` - Extracts hashtags
  6. `Html::Sanitize` - Sanitizes HTML

### Dynamic Variables for Pages
- **Syntax**: Uses `{{ }}` syntax (similar to Pika and BearBlog)
- **Available variables**: `{{ posts }}`, `{{ posts_by_year }}`, `{{ tags }}`, `{{ email_subscription }}`
- **Posts variable options**:
  - `{{ posts }}` - Shows all posts
  - `{{ posts limit: 10 }}` - Shows 10 most recent posts
  - `{{ posts tag: ruby }}` - Shows posts tagged with "ruby" (quotes optional)
  - `{{ posts year: 2025 }}` - Shows posts from 2025
  - Can combine: `{{ posts limit: 5 tag: rails }}`
- **Posts by year variable**:
  - `{{ posts_by_year }}` - Groups all posts by year with headers
  - `{{ posts_by_year tag: ruby }}` - Filter by tag
- **Tags variable**:
  - `{{ tags }}` - Outputs tags as a `<ul>` list (default)
  - `{{ tags style: inline }}` - Outputs tags as comma-separated inline links
- **Email subscription variable**:
  - `{{ email_subscription }}` - Embeds email subscription form
- **Implementation**:
  - `DynamicVariableProcessor` model (`app/models/dynamic_variable_processor.rb`)
  - Simple interface: `processor.process(content)` returns rendered HTML
  - Helper (`process_dynamic_variables` in `posts_helper.rb`) creates processor and calls `process`
- **Performance**: All variables use `.visible` scope and proper ordering to prevent N+1 queries
- **Usage**: Only processed in pages (is_page: true), not regular posts
- **Error handling**: Unknown variables appear literally in output (graceful degradation)
- **Testing**: Integration tests in `test/integration/custom_tags_rendering_test.rb` verify full rendering behavior
- **Disable prefetch**: Add `data: { turbo_prefetch: false }` to links in archive pages to prevent excessive prefetching

### Analytics Development
- **Key insight**: Analytics show zero data when no rollups exist BUT rollup job hasn't run yet
- **Solution pattern**: `Analytics::Base#cutoff_time` returns 1900-01-01 when no rollups exist, ensuring raw PageViews are always used until rollups are available
- **Data flow**: PageViews → (monthly job) → Rollups → PageViews deleted → Analytics use mixed data
- **Testing**: Use `Analytics::Base.new(blog)` for summary, `Analytics::Chart.new(blog)` for charts
- **Admin analytics**: Has month/year navigation, filters data by selected time period

### Styling & Components
- **Primary button**: `btn-primary` class uses `bg-[#4fbd9c]` and `hover:bg-[#4bb193]`
- **Component pattern**: Check existing implementations before creating new ones
- **Admin UI**: Uses slate colors with primary green accents for active states

### CSS Architecture
- **Typography system**: Uses `em` units for scalable content (font sizes, padding, margins within text)
- **Layout spacing**: Uses `rem` for CSS variables like `--lexxy-content-margin` (consistent across font sizes)
- **Logical properties**: Prefer `margin-inline-start` over `margin-left`, `padding-inline-start` over `padding-left` for RTL support
- **Blog styles**: All blog content uses `em` for relative scaling; app UI uses fixed Tailwind sizes
- **Component files**:
  - `lexxy-typography.css`: Core content typography (`.lexxy-content` wrapper)
  - `components.css`: Blog themes, app buttons, utility classes
  - `themes/*.css`: Color variable definitions per theme

### Blog Markup Architecture
**No Tailwind**: Public-facing blog views use semantic CSS classes instead of Tailwind utilities

**Layout**: Blog views use `layouts/blog.html.erb` (not `application.html.erb`)

**Layout Structure**:
```
<body class="[font-class]" data-theme="[theme-name]">
  └── <main>
      └── <div class="blog blog-container [max-w-content-*] text-size-standard">
          ├── Flash messages
          ├── <header> (top nav, titlebar, bio, email form)
          └── Content (posts list or individual post)
```

**Individual Post**:
```
<article>
  ├── <h1 class="post-title"> (optional)
  ├── <div class="lexxy-content"> (rich text with ActionText)
  ├── <div class="tags-container"> (optional)
  └── <footer> (date, reply, upvotes)
```

**Post List Layouts** (controlled by `@blog.layout`):
- **Stream**: `.post-stream-item` → Full post content in vertical list
- **Cards**: `.post-card` → Card grid with title, summary, meta
- **Titles**: `.posts-titles` → Chronological list grouped by year

**Key Classes**:
- `.blog-container` → Main content wrapper
- `.lexxy-content` → Rich text typography wrapper (em-based scaling)
- `.tags-container` → Tag badges
- `.empty-state` → Empty state messages
- `.flash-container` → Flash messages with fade animation

**Stimulus Controllers on Blogs**:
- `fade` → Flash message animations
- `media-embeds` → Transforms URLs into embeds (YouTube, etc.)
- `lightbox` → Image lightbox
- `syntax-highlight` → Code block highlighting

### Navigation System
- **NavigationItem model**: Unified navigation system using STI (Single Table Inheritance) for blog header links
- **Three types**:
  1. **PageNavigationItem**: Links to a Post (is_page: true) - label auto-syncs from post.title
  2. **CustomNavigationItem**: Manual label + URL (e.g., "Posts" → "/posts", "Archive" → "https://...")
  3. **SocialNavigationItem**: Social media icons with platform-specific rendering
- **Ordering**: `position` column (integer, default 0) with `.ordered` scope (`order(:position, :id)`)
- **Visibility**: `visible` boolean flag, `.visible` scope filters displayed items
- **Management**: Settings → Navigation (`app/settings/navigation_items`)
- **View rendering**: `@blog.navigation_items.visible.ordered` in `_nav.html.erb`
- **Legacy**: Old `show_in_navigation` column on Post model is deprecated (removed from UI)
- **Performance**: Uses `.includes(:post)` to avoid N+1 queries
- **URL generation**: `link_url` method returns `blog_post_path(post)` for pages, raw `url` for custom/social links
- **Stimulus controller**: `navigation_form_controller.js` handles page/custom toggle in settings form

#### SocialNavigationItem Details
- **Platforms**: Defined in `PLATFORMS` constant in `app/models/social_navigation_item.rb`
- **Current platforms**: Bluesky, Email, GitHub, Instagram, LinkedIn, Mastodon, Reddit, RSS, Spotify, Threads, TikTok, Web, X, YouTube
- **Icons**: SVG files stored in `app/assets/images/icons/social/{platform.downcase}.svg`
- **Icon pattern**: All icons use `fill="currentColor"` or `stroke="currentColor"` to adapt to theme colors
- **Adding new platforms**:
  1. Add platform name to `PLATFORMS` array (alphabetically sorted)
  2. Create matching SVG icon in `app/assets/images/icons/social/` (use lowercase filename)
  3. No other changes needed - views dynamically load icons using `inline_svg_tag`
- **Special handling**: Email platform uses `mailto:` prefix in `link_url` method
- **Validation**: Validates platform inclusion, URL format (HTTP/HTTPS for web, email format for Email platform)

### Security
- Brakeman for vulnerability scanning
- Admin constraints for Sidekiq/PgHero access
- Environment-based feature toggles
- **Privacy**: No raw IP storage, only visitor_hash for uniqueness detection

### Blog Export System
- **Two formats**: HTML (with layout) and Markdown (with front-matter)
- **Export process**: BlogExportJob creates ZIP files with all blog content
- **HTML exports**: Creates `index.html` + individual `.html` files for each post/page
- **Markdown exports**: Creates `index.md` + individual `.md` files with YAML front-matter
- **Image handling**: Downloads and includes referenced images in `images/` directory
- **File structure**: Uses post slugs as filenames, preserves relative image links
- **Auto-cleanup**: Exports are automatically deleted after 7 days
- **Status tracking**: pending → in_progress → completed/failed
- **Rate limiting**: 5 exports per day per user

#### Export Testing
- Test both HTML and Markdown format creation
- Verify `display_format` method returns "HTML" or "Markdown"
- Test controller accepts format parameter correctly
- Verify both index formats are created with proper links
- Test image downloading and path rewriting
- Test failed exports can still be deleted

## Code Style Guidelines
- **String quotes**: Always use double quotes for strings, not single quotes
- **Whitespace**: Remove trailing whitespace from all lines
- **Component pattern**: Check existing implementations before creating new ones
- **Method complexity**: Keep methods simple - prefer ternary operators over case statements for 2-option logic