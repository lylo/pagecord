# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Development Commands

### Setup
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
bin/rails test:system # Run system tests
```

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
- Key tables: users, blogs, posts, subscriptions, email_subscribers
- Soft deletion with Discard gem

### Background Processing
- Sidekiq for async jobs
- Jobs: email processing, image generation, subscription handling
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

### Security
- Brakeman for vulnerability scanning
- Admin constraints for Sidekiq/PgHero access
- Environment-based feature toggles