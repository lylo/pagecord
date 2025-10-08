# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Code Style & Conventions

**IMPORTANT**: When writing code for this project, always follow these principles:

### Ruby & Rails Style
- **Idiomatic Ruby**: Use Ruby conventions (`.map`, `.select`, `.find`, `&:method_name` shorthand, etc.)
- **Idiomatic Rails**: Follow Rails conventions (fat models, skinny controllers, RESTful routes, concerns for shared behavior)
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

### Performance
- **Avoid N+1 queries**: Use `.includes()`, `.eager_load()`, or `.preload()` when loading associations
- **Caching**: Leverage Rails fragment caching and Russian Doll caching patterns
- **Database indexes**: Add indexes for foreign keys and frequently queried columns
- **Query optimization**: Use `.select()` to limit columns, `.pluck()` for single values

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
- **NavigationItem**: Manages blog header navigation links (pages or custom URLs), with ordering via position column
- **SocialLink**: Social media links displayed as icons in blog header (separate from text navigation)
- **Email processing**: Uses ActionMailbox with PostsMailbox to create posts from emails

### Key Features
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
- **Email**: Postmark (inbound/outbound) and Mailpace (trial)
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

### Background Processing
- Sidekiq for async jobs
- Jobs: email processing, image generation, subscription handling, analytics rollups
- Redis required for job queue

## Development Notes

### Local Development
- Uses lvh.me for local subdomain testing
- Supports both pagecord.com and blog.lvh.me:3000 patterns
- Redis must be running for background jobs

### Email Testing
- Letter opener for development email preview
- Can process saved .eml files for debugging
- ActionMailbox handles inbound email parsing

### Liquid Tags
- **Custom environment**: `BlogLiquid` - separate from default Liquid
- **Available tags**: `{% posts %}`, `{% posts_by_year %}`, `{% tags %}`, `{% email_subscription %}`
- **Posts tag options**:
  - `limit: N` or `limit: false` (no limit)
  - `tag: 'ruby'` (filter by tag)
  - `year: 2025` (filter by year)
- **Posts by year**: Automatically groups posts by year with headers, accepts `tag:` parameter
- **Performance**: All tags use `.with_full_rich_text` in base relation to prevent N+1 queries
- **Usage**: Only processed in pages (is_page: true), not regular posts
- **Error handling**: Invalid liquid syntax returns original content (no "Liquid error" shown to users)
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

### Navigation System
- **NavigationItem model**: Unified navigation system for blog header links
- **Two types**:
  1. **Page links**: Link to a Post (is_page: true) - label auto-syncs from post.title
  2. **Custom links**: Manual label + URL (e.g., "Posts" → "/posts", "Archive" → "https://...")
- **Ordering**: `position` column (integer, default 0) with `.ordered` scope (`order(:position, :id)`)
- **Visibility**: `visible` boolean flag, `.visible` scope filters displayed items
- **Separate from social links**: SocialLink model handles icon-based social media links
- **Management**: Settings → Navigation (`app/settings/navigation_items`)
- **View rendering**: `@blog.navigation_items.visible.ordered` in `_top_nav.html.erb`
- **Legacy**: Old `show_in_navigation` column on Post model is deprecated (removed from UI)
- **Performance**: Uses `.includes(:post)` to avoid N+1 queries
- **URL generation**: `link_url` method returns `blog_post_path(post)` for pages, raw `url` for custom links
- **Stimulus controller**: `navigation_form_controller.js` handles page/custom toggle in settings form

### Security
- Brakeman for vulnerability scanning
- Admin constraints for Sidekiq/PgHero access
- Environment-based feature toggles
- **Privacy**: No raw IP storage, only visitor_hash for uniqueness detection