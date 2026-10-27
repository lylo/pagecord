# AGENTS.md

Ruby on Rails blogging app (Pagecord). Ruby, CSS, YAML, JavaScript.

## Principles

- **Vanilla Rails**: No services, commands, or interactors. Private methods in controllers, rich domain models, concerns for shared behavior. See [Vanilla Rails is Plenty](https://dev.37signals.com/vanilla-rails-is-plenty/).
- **Minimal code**: Fewer lines when clarity is maintained. Simple over clever. No over-engineering or premature abstraction.
- **Reuse existing code**: Before adding a helper, predicate, query object, or host/routing check, search for an existing app concept that already expresses it. Prefer calling the existing method over duplicating the logic.
- **Idiomatic**: Follow Ruby and Rails conventions throughout. Fat models, skinny controllers, RESTful routes.
- **Default Rails baseline**: For Rails coding, refactoring, debugging, migrations, and review tasks, apply the `rails-best-practices-core` skill unless a more specific instruction conflicts.
- **Extractions must be paid for**: a new class, concern, or scope earns its place with a second caller, a net deletion, or a bug it fixes. Tidiness is not a payer; single-caller logic stays with its caller.
- **Refactoring plans are hypotheses**: verify each claimed fact and claimed benefit against the code before building it. A plan's confidence is not evidence.
- **Suggest refactorings**: When you spot something worth improving next to the work in hand, say so. Describe it and let it be chosen, rather than silently widening the change.

## State changes

- **A GET must be safe.** Never write state in response to a GET, not even to a cookie or the session. Turbo prefetches links on hover, so a `link_to` that writes a preference fires just by passing the cursor over it. This is easy to miss because curl and integration tests never hover: the server looks correct in every probe while every browser misbehaves.
- **Toggles are singular resources.** An on/off preference is `create`/`destroy` on a `resource`, reached with `button_to` – `App::Posts::DetailsController` and `resource :spotlight_exclusion` are the pattern. A preference with a value is `update` on a singular resource taking the value as a param – `App::Pages::SortOrdersController`.
- **`button_to` inside a flex or grid container needs `form_class: "contents"`**, or the generated `<form>` becomes the layout child and breaks the arrangement. Inactive buttons need `cursor-pointer`, which links get for free.
- **`session` vs `cookies.encrypted`**: the session *is* an encrypted cookie, so encryption is not the distinction – lifetime is. The session expires after a year and dies with `sign_out`, so anything that should be remembered indefinitely belongs in `cookies.permanent.encrypted`: display preferences such as `posts_info` and `pages_sort`. Reserve `session` for state that is genuinely scoped to being signed in, and `cookies.encrypted` without `permanent` for values needing their own schedule, such as `upgrade_banner_dismissed` reappearing after 14–30 days.
- Storing a preference as an explicit value both ways (`"on"` / `"off"`) avoids the `cookies.delete` branch that a single toggle endpoint needs to express "back to default".

## Code Style

- Use British English spelling in user-facing copy and documentation (for example, "capitalisation", not "capitalization")
- Double quotes for strings, not single quotes
- Use en-dashes (–), never em-dashes (—)
- Remove trailing whitespace
- Private methods indented one additional level (2 spaces) after `private`
- Prefer ternary operators over case statements for 2-option logic
- Use `inline_svg_tag "icons/name.svg"` for SVGs – never hardcode `<svg>` elements
- Avoid N+1 queries: use `.includes()`, `.eager_load()`, or `.preload()`

### Comments

Write almost none. Name things well and let the code speak. A comment is warranted
only when a future reader would otherwise make a mistake: a non-obvious coupling
between files, a constant that must be kept in step with something else, a
deliberate deviation from the obvious approach. One line, ideally.

Never write a comment that:

- restates what the line below it does
- explains why a decision was made, or argues for it
- narrates what would break if the code were changed
- answers a question that came up while writing it

When one is warranted, say plainly what the thing is for or how it works, in the
words you'd use explaining it to someone at the next desk: "a password protected
blog is unlocked by storing its digest in the access cookie". Not what it defends
against, not what happens to whom if it changes. If the method name already says
it, write nothing.

Use the plain name of the thing: the selector, the file, the property. Never a
label coined while writing ("bare classes", "the rail", "the guard") unless the
code already uses it. If you touch an existing comment, rewrite it to this
standard rather than adding to it.

If a change needed explaining, the explanation belongs in the commit message or
the pull request, where it is attached to the change rather than to the file
forever. Code review comments are not code comments.

For calibration, Fizzy (`~/dev/fizzy` on the Mac, `~/Dev/fizzy` on Linux) runs at
roughly 2.6% comment lines across its models and controllers, counting non-blank
lines, against Pagecord's 4.5%. Its longest comment warns that a constant must be
updated when a model is added – a trap the code genuinely can't express.

## JavaScript & Frontend

- **Importmaps** only (NOT npm/yarn/webpack). Add packages: `bin/importmap pin package-name`
- **Stimulus only**: Never inline `<script>` tags or vanilla JS in views. No jQuery.
- Use Stimulus targets (not `querySelector`), actions (`data-action`), and values for data passing
- **Keyboard shortcuts** are Stimulus keyboard actions on the element that owns them: `keydown.esc->inline-edit#cancel`, or `command_key_action("k", "search#open:prevent")` for a ⌘/Ctrl chord. Hold-Shift keys are `hotkey_options` plus `hotkey` on a button or link. Never add a `keydown` listener in `connect`
- Prefer existing Stimulus components (e.g., `stimulus-sortable`) over custom implementations
- Use Turbo Frames and Streams for dynamic updates

## CSS & Styling

- **App views**: Tailwind utility classes with dark mode variants (`dark:bg-slate-800`, etc.)
- **Blog views**: Semantic CSS classes, NOT Tailwind. Layout: `layouts/blog.html.erb`. Typography uses `em` units for scaling.
- **Logical properties**: Prefer `margin-inline-start` over `margin-left` for RTL support
- Primary button colour: `btn-primary`, filled with `bg-pagecord-accent`

## Design System

Every app page renders inside a **sheet**: a white surface on the tinted page
background. The sheet's parts are component classes in
`app/assets/tailwind/components.css`: `.sheet`, `.sheet-bleed`, `.sheet-header`,
`.sheet-band`, `.sheet-divider`, `.page-title`, `.option-card`, `.option-radio`,
`.btn-icon`, and `.btn-group` with `.btn-group-item`. A view adds only layout modifiers to them (`justify-between`,
`py-5`, `flex-col`); it never restates their colours, borders or padding.

- **The sheet is the only bordered container.** Inside it, sections divide with
  edge-to-edge hairlines and soft fills; bordered panels are not used. Inputs keep
  their borders. The Settings index cards are a deliberate exception. A page can
  lay out several sheets by declaring `content_for :sheets`, which Settings does.
- **Every screen starts with a header row**: `sheet-header`, flush to the sheet's
  top edge with a hairline beneath. Breadcrumb or tabs on the left, actions on
  the right. It appears only when it has something to hold: a breadcrumb on a
  sub-page, or tools such as search and sort. Every screen then carries a
  `page-title`, and where it has actions a control row beneath: the primary
  action, a `btn-group` for any exclusive choice
  (Published/Drafts, Day/Month/Year, client-side panels), then a `sheet-divider`
  above the content. Breadcrumbs root at the nav section and are omitted where
  a nav tab already goes to the same place, as in the editors.
- **Full-bleed dividers**: rows carry `sheet-bleed` so the divider between them
  reaches the sheet's edges. A standalone rule is `sheet-divider`.
- **Spacing**: sheet body 32px, header row 16px, a row in a divided list 20px, a
  section boundary 24px either side of its rule, 24px below a tab strip. Tab
  panels are not rows: 24px above, 32px below.
- **Section headings** in Settings are a `sheet-band` (shaded fill with a
  hairline beneath), rendered by `settings_section`. In the first sheet the band
  sits below the page title and its rule; every later sheet opens with it. On
  list screens the sections are the `btn-group` in the control row, each item
  carrying a count `pill`.
- **Choices are option cards**: an `option-card` label wrapping an `option-radio`
  (or a hidden one). See the export format, typeface, layout, width and email
  delivery choosers.
- **Blank slates** are centred in the sheet, a heading and a line of copy over
  the primary action (Posts, Pages, Comments). Never a box floating inside the
  sheet.
- **Buttons** are one height: filled variants carry a transparent border so they
  match outline ones. Destructive actions always use `btn-danger`.
- **Placeholders** are set once in `components.css`; the editor's are in
  `lexxy-editor-overrides.css` so they beat Lexxy's own opacity. Never set a
  placeholder colour in a view.
- **Count pills** use the `pill` helper: `rounded-full`, slate-filled, low drama.
- **Admin** keeps its older cards and tables until it is redesigned. Only the
  Moderation pages use sheets, and each one wraps itself in a `sheet`; their
  status labels use `badge(text, tone)`.
- **Row hover** on a list: soft fill, title underlines, row icons brighten. Divided
  rows fill full-bleed; compact rows (posts, pages) fill an inset rounded strip.
- **Dark mode** keeps the page at `slate-950` and every surface, including the nav
  and menus, at `slate-900`; the sheet gets a 1px `slate-800` ring in place of a
  shadow. Structural hairlines are `dark:border-slate-800`; inputs and option
  cards keep `dark:border-slate-700` for affordance.
- **Text hierarchy**:
  - Headings and primary labels: `text-slate-900 dark:text-slate-100`
  - Supporting copy: `text-slate-600 dark:text-slate-300`
  - Meta text, dates, counts, secondary controls: `text-slate-500 dark:text-slate-400`
- **The grey scale is remapped** in `app/assets/tailwind/application.css` to
  slate's lightness steps at the accent's hue, so `slate-*` reads as a faintly
  green grey. Dark mode redefines the same scale cool and the accent light, so
  anything filled with the accent takes `dark:text-slate-950`. Don't reach for
  `zinc`, `stone` or `gray`.
- **Palette**: `pagecord-accent` (and `pagecord-accent-hover`) is the only
  brand colour; never write its hex in a view. Semantic colours are `red` for
  danger, `amber` for warnings, `sky` for information and `emerald` for success.
  The avatar palette in `_blog_avatar` is the one place other hues appear.
- **Consistency rule**: follow the treatment already used on Posts, Comments and
  Settings before inventing a new one.

## Testing

- Minitest with fixtures. Follow Rails conventions for file location.
- Focused tests for business logic – don't over-test
- Keep the suite fast. Lean on fixtures rather than creating records in the test,
  and never loop to build a pile of them to reach a threshold
- Don't test the framework or a gem. If the assertion would fail only because
  Pagy or Rails itself broke, delete it
- System tests are a last resort, for behaviour no other layer can reach. They
  are slow and prone to flaking; prefer an integration test every time
- UI review checklist: verify loading/sending/sent/error states, async redirects and background-job timing, and subscriber/count reads after async work completes. Run relevant system tests when they exist.
- **System test gotchas**:
  - Flash messages are initially hidden; use `assert page.has_content?("Text", wait: 2)` not `assert_text`
  - Never `sleep`. Wait on the observable outcome: a Capybara waiting assertion for the DOM, or a bounded early-exit poll for a database write
  - `test/test_helper.rb` sets `I18n.locale = :en` for every test, so tests needn't set it themselves

## Git Commits

- **Check the checkout first.** If `git rev-parse --abbrev-ref HEAD` is
  `gitbutler/workspace`, this is a GitButler workspace: use `but` for every write
  (`but diff` for file and hunk IDs, `but commit -b <branch> -m "..." <id>`,
  `but push <branch>`). Never `git add`, `commit`, `checkout`, `rebase` or `stash`
  here – a raw commit lands in the workspace commit and mixes every applied branch
  together. If `but` isn't available on that branch, stop and ask rather than
  falling back to git. On an ordinary checkout, plain git is fine.
- Several branches share one working tree, so other agents' edits show up in your
  diff. Commit the specific file or hunk IDs your change touched, never everything
  uncommitted, and leave other branches' changes alone.
- Work reaches `main` by `but land <branch>`, which fast-forwards `main` and
  pushes, when asked to push to `main`, land or ship. No pull request is needed;
  open one only when asked.
- Run `bin/ci` before landing. Its gem audit can turn `main` red with no
  code change, when a new advisory is published.
- Use plain branch names without category prefixes (for example `help-dialogs`, not `feature/help-dialogs` or `fix/help-dialogs`)
- Use plain PR titles without automation prefixes (for example `Help dialogs`, not `[codex] Help dialogs`)
- **NEVER** add "Co-Authored-By", "Generated with Claude Code", or any AI attribution to commit messages, PR descriptions, or code comments. This is a hard rule – no exceptions.
- **NEVER** put customer data in commit messages, PR descriptions, code comments, test names, or test data: no subdomains, emails, names, user ids, or Paddle customer ids. Describe the shape of a case ("a cancellation requested weeks before it takes effect"), never the customer it came from. This is a hard rule – no exceptions.
- Commit to a branch and push it without asking once the change is verified: tests
  pass, or it has been checked against real data, and rubocop is clean. Landing on
  `main` still waits for an explicit instruction.
- Ask before committing changes to billing, authentication, data migrations or
  customer email, and leave design and copy uncommitted while it's still being
  iterated on.

## Tooling

- **Rubocop** auto-runs on every file edit/write via a PostToolUse hook (see `.claude/settings.json`). It runs on the host on both machines, so after a Rails bump run `bundle install` there too, or every lint fails silently
- **CI** (`bin/ci`, or the `/ci` skill): the full local pipeline, declared in `config/ci.rb`
- **Sentry, Support and Fizzy skills** (`/sentry`, `/support`, `/fizzy`) live in the user's `~/.claude/skills`, not the repo. Use `/fizzy` for any tracker work rather than hand-rolling the API
- **Pagecord CLI** (the `lylo/pagecord-cli` repo): its agent skill ships with the gem (`pagecord skill install`). Against the dev server, log in with `pagecord login SUBDOMAIN --base-url http://api.localhost:3000` – the `api.` host is required
- **Pagecord blog drafts**: write reviewable Obsidian posts to `Pagecord Blog Posts` in the vault: `/Users/olly/Notes/Personal` on the Mac, `/home/olly/Documents/Primary` on Linux

## Commands

Two machines are in daily use:

- **Mac** (laptop): everything runs natively on the host, Postgres included.
- **Linux** (desktop): Rails, tests and `bin/ci` run in Docker, as there is no host
  Postgres. Prefix them with `docker compose exec -T web`; without `-T`,
  non-interactive commands hang. Rubocop and brakeman also run on the host.

```bash
bin/dev                          # Start app (Rails, Tailwind, Redis, Sidekiq)
bin/ci                           # Full local pipeline
bin/rails test                   # Unit tests
bin/rails test:system            # System tests
bundle exec rubocop              # Linter
bundle exec brakeman             # Security scanner
```

## Architecture

- **Core models**: User has many Blogs (`user.blogs`, discarded ones in `all_blogs`; `User#blog` is just the first). `Blog::MAX_BLOGS_FREE` is 1, `MAX_BLOGS_PAID` 3. Blog has many Posts (posts and pages split by `is_page`), a `home_page`, NavigationItems (STI: Page, Posts, Search, Custom, Social), EmailSubscribers and SenderEmailAddresses. Post has many Upvotes, `Post::Comment`s (threaded, moderated, on the blog) and `Post::Reply`s (private replies emailed to the owner) – two separate systems
- **Auth**: Magic links via AccessRequest (1-day expiry, `purpose` login or password_reset), plus optional passwords (`PasswordSecured`). EmailChangeRequest and SenderEmailAddress use the Verifiable concern; AccessRequest has its own token handling
- **Routing**: Constraint-based – pagecord.com for app/auth, `api.` host for the API, subdomains and custom domains for blog content
- **Storage**: ActiveStorage on Cloudflare R2. Soft deletion with Discard (User, Blog, Post); `accounts:purge_cancellations` hard-deletes accounts discarded over 7 days ago. `UploadQuota` (a PORO over User) is the single source of truth for what a user has uploaded – count, bytes, and what their plan still allows. `rake activestorage:users` reports it. `RemoveImageLocationJob` strips GPS (EXIF and XMP) from every photo once it is uploaded, losslessly via `exiftool` (needed on the server and in CI).
- **API**: `Api::BaseController` handles token auth via `Blog.find_by_api_key`, premium check, 60 req/min rate limit, `wrap_parameters false`, and RFC 5988 `Link` + `X-Total-Count` pagination headers. `Api::BadRequestError` is the 400, `Api::ForbiddenError` the 403 for subscriber-only settings. Post and page params are built by `Api::PostParams` (markdown rendering, status validation, attachment enrichment). Controllers: Posts, Pages, HomePages (singular; second create returns `422`, destroy only unsets it), Attachments (file upload → standalone blob → `attachable_sgid`), `Settings::Appearance`, `Settings::CustomCode`, and Micropub with its media endpoint. `content` is always stored as HTML; `content_format=markdown` first renders via Redcarpet with front matter support, then attachment enrichment runs on the resulting HTML. API rich text attachments are blob-only and canonicalized with the same `ActionText::Attachment.from_attachable(..., url: ...)` path used by MailParser via `Html::AttachmentPreview`. Upload limits live in `UploadLimits::CONTENT_TYPES` (`app/models/upload_limits.rb`).
- **MCP**: `Api::McpController` serves `api.<domain>/mcp` as a stateless Streamable HTTP server, hand-rolled JSON-RPC with no gem: `initialize`, `ping`, `tools/list`, `tools/call`, notifications get a 202 and GET a 405. Tools are `Mcp::Tools::*` subclasses of `Mcp::Tool` (`describe` sets description, schema and annotations; `perform(blog, **arguments)` does the work) and reuse `Api::PostParams`. Auth is the blog's API key or an `McpConnection` token from the OAuth flow (`Oauth::*` controllers: stateless signed `client_id` from dynamic registration, PKCE S256, one-shot codes, no refresh tokens). Connections are listed and revoked in Settings > API. Rack::Attack leaves a `/mcp` request with a valid token to the per-blog `rate_limit`, because Claude and ChatGPT share egress addresses; anything else stays on the per-IP throttles.
- **Caching**: `blog.updated_at` is the single invalidation boundary. Everything that changes visitor-visible state touches the blog. There are no post fragment caches (only the RSS feed has a `cache` block); post pages use `fresh_when` ETags on `[post.id, blog.updated_at]`. Blog `after_commit :purge_cloudflare_cache` (on update, production only, debounced 5s through a `Rails.cache` lock) fires `PurgeCloudflareCacheJob` (tag-based purge by subdomain). Edge caching (`s-maxage`, `Cache-Tag`, session skip) only applies to `*.pagecord.com` – custom domains route through Caddy, not Cloudflare. Upvotes don't invalidate caches (display is handled client-side via Stimulus).
- **Background**: Sidekiq + Redis (Redis is used only by Sidekiq). `Rails.cache` is Memcached, holding mostly Rack::Attack and `rate_limit` counters. Cron via `whenever` (see `config/schedule.rb`)
- **Custom domains**: customers CNAME or ALIAS to `proxy.pagecord.com` (or an A record to its IP). Caddy issues certificates on demand after asking `CustomDomains::VerificationsController`. Serving and certificates are gated by `custom_domain_access?` (subscribed, or within a 30-day grace after lapse), not `subscribed?`
- **External services**: Cloudflare Email Sending (transactional email) + Postmark (digests and inbound), Sentry (errors), AppSignal (observability), Hatchbox (hosting), Paddle (billing), OpenAI (moderation), CleanTalk (spam), Cloudflare Turnstile, Plausible, DB-IP GeoIP

### Billing & Access
- **Payments**: Paddle webhooks (`Billing::PaddleEventsController`) → Subscription model. Plans: monthly, annual, supporter, complimentary
- **Trial**: 14-day free trial. `has_premium_access?` = subscribed OR on trial. `subscribed?` = an active subscription, complimentary included; `paying?` = a paid plan only.
- Trial-eligible (`has_premium_access?`): analytics, comments, reply by email, contact form, custom Open Graph images, writing custom CSS and footers, API and Micropub
- Subscriber-only (`subscribed?`): setting a custom domain, email subscriptions, branding removal, custom head/body HTML, uncapped uploads, video uploads, custom robots.txt, up to 3 blogs. Subscribers also skip content moderation
- Free on every plan: avatar, post likes, search, colour schemes and Theme Garden designs, tags, RSS, export, 20 uploads (`UploadQuota::FREE_LIMIT`)
- **Uploads**: `UploadQuota` (PORO over User) is the single source of truth – count, bytes, and what the plan allows. Enforced by `UploadQuota::Validator` on Post; the direct-upload endpoint check is an advisory pre-check only. A save that crosses the limit is allowed; the next upload is refused. Only blobs a save *introduces* are checked, so a lapsed subscriber can still edit old posts
- **Lapsing**: content and appearance you made keeps rendering (custom CSS, footer, robots.txt, uploads); custom head/body HTML stops. Ongoing services stop (newsletter, analytics, API), and so do `Blog#accepts_replies?` and `#accepts_subscribers?`. Custom domains keep working for the 30-day grace, then `Blogs::ClearLapsedCustomDomainsJob` clears them. `Blog#branding_visible?` brings our branding back
- Payment failures handled automatically by Paddle Retain – don't email customers about failed payments
- **Invoices**: customers view past invoices via Paddle's customer portal. `App::Settings::Subscriptions::PaddleInvoicesController#show` mints a portal session (`POST customers/:id/portal-sessions`) and redirects – don't build an inline invoice list

### Content Pipeline
- **Email-to-blog**: ActionMailbox → PostsMailbox → MailParser (HTML pipeline: body extraction → monospace detection → image unfurl → inline attachments → tag extraction → sanitize; plain text: to HTML → tags → image unfurl). `digest-reply-*` addresses go to DigestReplyMailbox instead
- **Content moderation**: OpenAI API via `ContentModerator`. `ContentModerationBatchJob` runs hourly, queuing up to 100 posts changed in the last 24h. Flagged posts stay visible for admin review. Daily digest to admin via `ContentModerationDigestJob`.
- **Spam detection**: comments, email replies and contact form messages (`SpamCheckable`) go through `MessageSpamDetector`, backed by CleanTalk. Every signup is screened in the background (`ScreenUserJob`, which retries CleanTalk timeouts, → `User::Screenable#screen`, CleanTalk `check_newuser`) and the checks it failed kept in `User::Screening`. Nothing is blocked yet: the moderation queue labels failed screenings, and the Screening tab (`User::Screening::Accuracy`) compares them with manual review as false positives and missed spam. Request-level guards (honeypot, Tor, timing, Turnstile, suspicious emails) stay in `SpamPrevention`.
- **Dynamic variables**: `DynamicVariableProcessor::TAGS` is the list (`posts`, `posts_by_year`, `tags`, `email_subscription`, `contact_form`, `search`, `table_of_contents`, `updated_at`…). Processed in pages only (`is_page: true`); code blocks are left alone
- **Excerpt break**: `{{ more }}` or `<!--more-->` marker splits a post into a teaser and the rest. `ExcerptBreak` parses the marker; `Post#excerpt_html` exposes the teaser (computed on demand, memoized – no DB column). Stream layout renders teaser + "Read more" link; cards use `card_excerpt_html` (`Html::CardExcerpt`): the full teaser as plain paragraphs, or the post cut at 324 characters. Full post views, RSS, and digest emails render full content with the marker stripped. Help doc: `docs/help-guide/excerpt-breaks.md`.
- **OG images**: chosen at render time by `OpenGraphHelper#open_graph_image`: an uploaded `post.open_graph_image`, else the first image, else a signed URL to the external OG worker

### Analytics
- PageView (raw, recent) + `Rollup` (from the `rollups` gem, historical). `RollupAndCleanupPageViewsJob` runs monthly, rolling up and deleting views older than the previous month.
- `app/models/analytics/`: `Base` (cutoff_time), `Summary`, `Chart`, `Referrers`, `Trending`, `Leaderboard`, `Countries`; `AdminReport` backs the site-wide admin dashboard; `DemoData` is the sample data non-premium users see
- Privacy: visitor_hash (SHA256 of IP+UA+date), no raw IPs
- Referrer tracking with domain normalization, search/social classification via `Referrer` model

### Email Features
- **Mailers**: transactional mail inherits `CloudflareMailer`; subscriber-facing mail (digests, digest replies, subscription confirmations) inherits `PostmarkMailer`
- **Post digests**: Emails to confirmed EmailSubscribers. Two delivery modes (`email_delivery_mode` enum in `EmailSubscribable`):
  - **Digest** (default): cron runs `post_digests:deliver` hourly on Tuesdays; `PostDigestScheduler` queues `GeneratePostDigestJob` for blogs where it is 8am in the owner's timezone. `PostDigest.generate_weekly_digest_for` finds new posts since last digest.
  - **Individual**: User manually sends single posts from the post editor via `App::Posts::BroadcastsController`. `PostDigest.generate_individual_for` creates a one-post digest. `Post::Emailable` concern provides `individually_sendable?`/`send_to_subscribers!`.
  - Both modes reuse the same infrastructure: `PostDigest` (with `kind` enum: `weekly_digest`/`individual`) → `PostDigest::DeliveryJob` (`newsletters` queue) → `PostDigest::PostmarkDelivery` (batches of 50, production only; other environments send through `PostDigestMailer`). Posts sent individually are excluded from future weekly digests via `DigestPost` join records.
  - Requires `email_subscriptions_enabled` + `subscribed?`. Custom sender addresses via `SenderEmailAddress` (max 3 per blog, requires verification).
- **Reply by email**: a `Post::Reply` from the blog's form goes through `SendPostReplyJob` (spam check) to `ReplyMailer`. Replies to digest emails are forwarded by `DigestReplyMailer`, from confirmed subscribers only.
- **Blog export**: HTML or Markdown ZIP via `BlogExportJob`. Auto-cleanup after 7 days. Rate limited to 5/day.

### Lifecycle Emails
- **Welcome**: `WelcomeMailer.welcome_email` after email verification
- **Unengaged follow-up**: Monthly `SendUnengagedFollowUpEmailsJob` emails verified, unsubscribed users with no posts after 1 month. Tracked by `UnengagedFollowUp` model (one per user).
- **Trial**: daily `SendTrialReminderEmailsJob` (3 days before the end) and `SendTrialEndedEmailsJob`, both via `FreeTrialMailer`
- **Renewal reminders**: `Subscription::SendRenewalRemindersJob` emails every paid plan 2 weeks before `next_billed_at`, at most once a year
- **Cancellation**: `SendCancellationEmailJob` sends appropriate email (subscriber vs free account). `DestroyUserJob` soft-deletes, records an `AccountTombstone` and cancels Paddle; the hard delete comes later (see Storage).

### Feature Toggles
- Feature flags are stored on `users.features` as an array column. None are defined right now.
- Define one in `config/features.rb` using the `feature_toggles` gem: `feature :name do |user: nil, blog: nil| ... end`
- `ApplicationController#current_features` returns `Rails.features.for(user: Current.user, blog: @blog)` and is exposed to controllers/views. In app code prefer `current_features.enabled?(:feature_name)`; in models check `user.features.include?("feature_name")`.
- Feature-gated app UI should also guard direct routes with a `before_action` and redirect when disabled.

### Key Concerns
- **Subscribable**: Trial management (14 days), `has_premium_access?`, `subscribed?`, `paying?`, `custom_domain_access?`
- **Themeable**: 7 preset themes + custom, fonts, page widths, hex color validation
- **Blog::Design**: a Theme Garden design is a `ThemeTemplate` row (metadata only) plus a stylesheet in `app/assets/stylesheets/themes/<slug>.css`, linked on the blog page before the blog's own `custom_css` via `theme_template_id` + `theme_template_version`. No template is Classic. Small fixes (no intended visual change) edit the file in place; a redesign is `<slug>-2.css` with `version` bumped, and blogs keep the version they applied until `theme_templates:usage` (discarded blogs included) shows a file unused. There's no admin: a new design, a version bump or a reorder is a data migration plus the file, and a slug never changes once saved. `blogs.css` takes structural changes only, never look changes
- **Sluggable**: URL slug generation with reserved words
- **Taggable**: Tag management with validation, normalization, querying
- **Verifiable**: Token-based verification with 24h expiry (EmailChangeRequest, SenderEmailAddress)
- **CssSanitizable**: Custom CSS validation (24KB limit)

### Media Embeds

Client-side system that replaces bare links (URL = link text, alone on its line) with rich embeds, in `.post-body` on blog pages and in the editor.

- **Registry**: `app/javascript/embeds/media_sites.js` lists every site in match order – first match wins, so broad patterns go last. A new site needs a module there and a `preload: false` pin in `config/importmap.rb`. Posts store the bare link, never the iframe.
- **Editor**: `app/javascript/editor/embed_node.js` renders the same embeds via `editorMediaSites()`; Strava and plain images are excluded (`NOT_IN_EDITOR`).
- **Base class**: `app/javascript/embeds/media_site.js` takes `(regex, getEmbedUrl, createEmbedIframe)`.
- **Sites**: YouTube (incl. YouTube Music, playlists), Spotify, Apple Music and Podcasts, Tidal, Bandcamp, Transistor (`share.transistor.fm`), Strava (injects strava-embeds.com's script), GitHub Gists (`srcdoc`), Bluesky (resolves handles via `public.api.bsky.app`, resizes via `postMessage`), direct image URLs.
- **Bandcamp**: its embed URL is only in the page's `og:video` tag, which CORS hides from the browser, so `bandcamp.js` GETs `Api::Embeds::BandcampController#show`, which fetches it server-side, caches it 7 days and returns it. If the tag is missing, the embed is skipped.
- **CSP**: blog pages (`BlogContentSecurityPolicy`) and the editor (`EditorContentSecurityPolicy`) allow any `https` frame, so a new embed domain needs no CSP change. `config/initializers/content_security_policy.rb` is the app's report-only policy.

## Key Gotchas

- **ActionText before_save**: Read from `content.to_s` directly – ActionText changes aren't persisted until callback completes
- **Rich text save N²**: `ActiveStorage::Attachment`'s auto-generated presence validator on `:record` calls `RichText#blank?`, which re-renders the whole body and re-resolves every attachment's SGID – one full render per embedded attachment, so N photos cost N² blob queries (~1,161 for a 33-photo post). `config/initializers/active_storage.rb` swaps the validator for a cheap nil check; a query-budget test in `test/models/post_test.rb` guards it. Never add an `EachValidator` to an attribute that returns a `RichText` – `value.blank?` renders.
- **API Markdown attachments**: Redcarpet wraps standalone raw `<action-text-attachment>` tags in `<p>` tags. `Api::PostParams` must unwrap attachment-only paragraphs after Markdown conversion or rendered blog HTML loses the outer `<action-text-attachment>` wrapper.
- **Safari**: Doesn't support `*.localhost` – use Chrome/Firefox for subdomain testing
- **Blog views**: No Tailwind. Blog styles are `blogs.css`, `blog-themes.css` and the `lexxy-*.css` files in `app/assets/stylesheets/`
- **Post text_summary**: Cached plain text column updated via before_save. Use `display_title`, `summary(limit:)` – don't parse ActionText in loops
- **Analytics**: Uses mixed data (raw PageViews for recent, Rollups for historical). `cutoff_time` returns 1900-01-01 when no rollups exist to ensure raw data is always used.
- **Client IP**: Use `request.ip` / `req.ip`. The `cloudflare-rails` gem (production only) patches Rack/Rails proxy checks so X-Forwarded-For is walked correctly past Cloudflare's edges. Never parse `HTTP_X_FORWARDED_FOR` yourself – the leftmost value is attacker-controlled and bypasses Rails' trusted-proxy filtering. Rack 3 also honours RFC 7239 `Forwarded` ahead of X-Forwarded-* by default; we pin `Rack::Request.forwarded_priority = [:x_forwarded]` in `config/initializers/rack_request.rb` to neutralise that. (See incident 2026-05-01.)
