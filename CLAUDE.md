# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

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
- **Blog**: Belongs to user, has many posts/pages, handles custom domains and theming
- **Post**: Blog content with rich text, attachments, and scheduling. Includes both posts and pages (is_page flag)
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
- Key tables: users, blogs, posts, subscriptions, email_subscribers, page_views, rollups
- Soft deletion with Discard gem

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