# GEMINI.md - Pagecord Project Knowledge Base

This document summarizes key aspects of the Pagecord project, derived from `CLAUDE.md`, to aid in future development and maintenance.

## Project Overview

Pagecord is a blogging application with features like email-to-blog posting, custom domains, rich text editing, and analytics. It leverages Ruby on Rails with Hotwire/Stimulus for a modern web experience.

## Code Style & Conventions

### Ruby & Rails
- **Idiomatic Ruby and Rails**: Follow standard Ruby conventions (`.map`, `.select`, `&:method_name`) and Rails patterns (fat models, skinny controllers, RESTful routes, concerns).
- **Vanilla Rails**: No services, commands, or interactors - use private methods in controllers and rich domain models. See [Vanilla Rails is Plenty](https://dev.37signals.com/vanilla-rails-is-plenty/).
- **Minimal & Elegant**: Prioritize clear, concise, and simple solutions. Avoid over-engineering.
- **ActiveRecord**: Utilize scopes, associations, validations, and callbacks.
- **Private Methods**: Indent private methods by two additional spaces after the `private` keyword.

### JavaScript & Frontend
- **Importmaps**: Used for package management (NOT npm/yarn/webpack). Add packages with `bin/importmap pin package-name`.
- **Stimulus**: ALWAYS use Stimulus for JavaScript. Avoid inline `<script>` tags or vanilla JS in views.
    - **Naming**: Descriptive controller names (e.g., `navigation_form_controller.js`).
    - **Best Practices**: Use Stimulus components, targets, actions, and values.
- **No jQuery**: Modern Rails app using Hotwire/Stimulus.
- **Turbo**: Leverage Turbo Frames and Streams for dynamic updates.

### Testing
- **Focused Tests**: Write tests for business logic, validations, and key methods. Avoid over-testing.
- **Fixtures**: Use fixtures for test data.
- **Minitest**: Use Minitest assertions.
- **Location**: Follow Rails conventions (`test/models/`, `test/controllers/`, etc.).
- **System Tests**: Be mindful of flakiness.
    - **Flash Messages**: Wait for visibility (`assert page.has_content?("Text", wait: 2)`).
    - **Form Submissions**: Allow `sleep` for async operations.
    - **Locale**: Ensure English locale (`I18n.locale = :en`) in setup.

### CSS & Styling
- **Tailwind CSS**: Use utility classes for styling.
- **Existing Patterns**: Check existing components before creating new styles.
- **Primary Color**: `bg-[#4fbd9c]` for primary buttons (`btn-primary`).
- **Dark Mode**: Always include dark mode variants (e.g., `dark:bg-slate-800`).
- **Blog Markup Architecture**: Public-facing blog views use semantic CSS classes, not Tailwind utilities. Layout uses `layouts/blog.html.erb`. `em` units for scalable blog content, `rem` for layout spacing.
- **Logical Properties**: Prefer `margin-inline-start` over `margin-left` for RTL support.

### SVG Icons
- **Always use `inline_svg_tag`**: Never hardcode `<svg>` elements in views - use `inline_svg_tag "icons/name.svg"`.
- **Icon location**: Store SVGs in `app/assets/images/icons/` (with `social/` subdirectory for social icons).
- **currentColor**: All icons should use `fill="currentColor"` or `stroke="currentColor"` to inherit text color.
- **Exceptions**: Dynamically generated SVGs (e.g., analytics charts) may use inline markup.

### Performance
- **N+1 Queries**: Avoid by using `.includes()`, `.eager_load()`, or `.preload()`.
- **Caching**: Utilize Rails fragment and Russian Doll caching.
- **Database Indexes**: Add indexes for foreign keys and frequently queried columns.
- **Query Optimization**: Use `.select()` and `.pluck()` to limit data.

### Code Review Checklist
- No inline JavaScript (all in Stimulus controllers).
- Idiomatic Ruby/Rails patterns used.
- Tests written and passing.
- N+1 queries avoided.
- Dark mode styles included.
- Documentation added to `CLAUDE.md` (if significant feature).

### Style Guidelines
- **String Quotes**: Always use double quotes.
- **Whitespace**: Remove trailing whitespace.
- **Component Pattern**: Check existing implementations before creating new ones.
- **Method Complexity**: Keep methods simple.
- **No Line Numbers**: Never include line numbers (e.g., 1:, 2:) in code snippets or console queries provided to the user.

## Development Commands

### Docker Setup (Preferred)
- `docker-compose up`: Start all services (Rails, PostgreSQL, Redis, Memcached).
- `docker-compose up -d`: Start in background.
- `docker-compose down`: Stop and remove containers.
- `docker-compose exec web COMMAND`: Run command in running container.
- `docker-compose run web COMMAND`: Run command in new container.

### Docker Development Commands
- `docker-compose exec web bin/rails console`
- `docker-compose exec web bin/rails test`
- `docker-compose exec web bin/rails test:system`
- `docker-compose exec web bin/rails db:migrate`
- `docker-compose exec web bundle exec rubocop`
- `docker-compose exec web bundle exec brakeman`

### Native Setup (Alternative)
- `bundle install`
- `rails db:setup`
- `brew install redis`

### Running the App
- `bin/dev`: Starts Rails, Tailwind CSS watcher, Redis, and Sidekiq.

### Testing
- `bin/rails test`: Run unit tests.
- `bin/rails test:system`: Run system tests (won't work in Docker).
- `bin/system-test`: System tests with Docker database (run on host).

### Linting and Code Quality
- `bin/rails db:migrate`
- `bundle exec rubocop`
- `bundle exec brakeman`

## Code Architecture

### Core Models
- **User**: Authentication, subscription, one blog.
- **Blog**: Belongs to user, many posts/pages, navigation_items, custom domains, theming.
- **Post**: Blog content (posts/pages via `is_page` flag), rich text, attachments, scheduling.
- **NavigationItem**: Manages blog header links (pages or custom URLs), with ordering.
- **SocialLink**: Icon-based social media links in blog header.
- **Email processing**: ActionMailbox with `PostsMailbox` for creating posts from emails.

### Key Features
- **Content Moderation**: Automated post moderation using OpenAI.
    - **Models**: `ContentModeration` (stores results), `ContentModerator` (service class), `Post::Moderatable` (concern).
    - **Flow**: `ContentModerationBatchJob` (hourly) finds posts needing moderation -> `ContentModerationJob` -> OpenAI API -> Flags/Cleans.
    - **Actions**: Flagged posts remain visible for admin review. Daily digest email with flagged post count.
    - **Admin**: `Admin::Moderation::ContentController` for reviewing flagged content (dismiss or discard).
- **Spam Detection**: New blog screening using GPT-4o-mini.
    - **Models**: `SpamDetection` (stores results), `SpamDetector` (service class).
    - **Flow**: `SpamDetectionJob` (daily) finds blogs 2 hours to 7 days old without existing check -> `SpamDetectionCheckJob` -> GPT-4o-mini -> Flags spam/uncertain.
    - **Timing**: Waits 2+ hours after blog creation so spammers have time to reveal themselves.
    - **Skips**: Subscribed users are not checked.
    - **Admin**: `Admin::Moderation::SpamController` for reviewing spam detections (confirm discards user, dismiss clears flag).
- **Email-to-blog**: Primary posting method via ActionMailbox.
- **Custom Domains**: Premium feature using Hatchbox API.
- **Rich Text**: ActionText for post content.
- **Background Jobs**: Sidekiq for async processing (email, image generation).
- **Subscriptions**: Paddle integration for payments.
- **Multi-tenancy**: Blog subdomains (e.g., `joel.pagecord.com`).

### Domain Routing
- Default domain (`pagecord.com`): Marketing, auth, app routes.
- Custom/subdomain blogs: Blog-specific content, RSS feeds.
- Constraint-based routing separates main app from blog content.

### Storage & External Services
- **ActiveStorage**: Images on Cloudflare R2.
- **Email**: Resend (inbound/outbound)
- **Monitoring**: Sentry (errors), AppSignal (observability).
- **Hosting**: Single Hetzner server via Hatchbox.

### Database
- PostgreSQL, standard Rails migrations.
- Key tables: `users`, `blogs`, `posts`, `navigation_items`, `social_links`, `subscriptions`, `email_subscribers`, `page_views`, `rollups`.
- Soft deletion with Discard gem.

#### Post Model Performance
- **`text_summary` column**: Cached plain text from ActionText, updated via `before_save` callback.
- **Purpose**: Avoids N+1 queries for post lists.
- **Methods**: `display_title`, `summary(limit:)`, `has_text_content?`.
- **ActionText gotcha**: In `before_save`, read from `content.to_s` directly.

### Analytics System
- **`PageView` model**: Tracks individual views with `visitor_hash` (SHA256 of IP+UA+date for privacy).
- **`Rollup` model**: Aggregated analytics data using `rollups` gem.
- **Mixed Data**: Uses raw `PageViews` for recent data, `Rollups` for historical.
- **`Analytics::Base`**: Core class with `cutoff_time` logic.
- **`Analytics::Summary`**: Handles summary metrics.
- **`Analytics::Chart`**: Generates chart data (month/year views).
- **`RollupAndCleanupPageViewsJob`**: Monthly job for rollups and `PageView` deletion.

### Background Processing
- Sidekiq for async jobs.
- Jobs: email, image generation, subscriptions, analytics rollups.
- Redis required.

## Development Notes

### Local Development
- Uses `localhost` for local subdomain testing (e.g. `joel.localhost:3000`).
- Note: Safari doesn't support `*.localhost` - use Chrome/Firefox for subdomain testing.
- Redis must be running.

### Email Testing
- Letter opener for development email preview.
- Can process saved `.eml` files (`DIR=tmp/emails rake email:load`).
- ActionMailbox handles inbound email parsing.

### Email Parsing (`MailParser`)
- **Location**: `app/models/mail_parser.rb`.
- **Purpose**: Parses inbound emails into structured content (subject, body, attachments, tags).
- **Strategy**: Uses Mail gem, handles Apple Mail RFC violation for `multipart/alternative` with multiple HTML fragments.
- **Attachment handling**: Processes unreferenced attachments.
- **Pipeline Transformations**:
    1. `Html::BodyExtraction`
    2. `Html::MonospaceDetection`
    3. `Html::ImageUnfurl`
    4. `Html::InlineAttachments`
    5. `Html::ExtractTags`
    6. `Html::Sanitize`

### Dynamic Variables for Pages
- **Syntax**: `{{ }}` (similar to Pika and BearBlog).
- **Available Variables**: `{{ posts }}`, `{{ posts_by_year }}`, `{{ tags }}`, `{{ email_subscription }}`.
    - `posts` options: `limit`, `tag`, `year`.
    - `tags` options: `style: inline`.
- **Implementation**: `DynamicVariableProcessor` model (`app/models/dynamic_variable_processor.rb`).
- **Performance**: Uses `.visible` scope and ordering to prevent N+1.
- **Usage**: Processed only in pages (`is_page: true`).
- **Error Handling**: Unknown variables appear literally.
- **Testing**: Integration tests in `test/integration/custom_tags_rendering_test.rb`.
- **Disable prefetch**: Add `data: { turbo_prefetch: false }` to links in archive pages.

### Navigation System
- **`NavigationItem` model**: Unified system for header links.
- **Types**: Page links (to `Post` with `is_page: true`) or Custom links (manual label/URL).
- **Ordering**: `position` column with `.ordered` scope.
- **Visibility**: `visible` boolean flag.
- **Management**: Settings → Navigation.
- **Performance**: Uses `.includes(:post)` to avoid N+1.
- **Stimulus controller**: `navigation_form_controller.js` for form toggling.

### Security
- Brakeman for vulnerability scanning.
- Admin constraints for Sidekiq/PgHero.
- Environment-based feature toggles.
- Privacy-focused: No raw IP storage.

### Blog Export System
- **Formats**: HTML (with layout) and Markdown (with front-matter).
- **Process**: `BlogExportJob` creates ZIP files.
- **Content**: `index.html`/`index.md` + individual files for posts/pages.
- **Images**: Downloads and includes referenced images.
- **Cleanup**: Exports deleted after 7 days.
- **Status**: `pending` → `in_progress` → `completed`/`failed`.
- **Rate Limiting**: 5 exports per day per user.
- **Testing**: Verify format creation, links, image handling, status, rate limiting.

This `GEMINI.md` file serves as my internal knowledge base for the Pagecord project.