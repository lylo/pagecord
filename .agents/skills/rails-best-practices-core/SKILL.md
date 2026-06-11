---
name: rails-best-practices-core
description: Apply core Ruby on Rails best practices for architecture, naming, RESTful routing, authorisation, safety, and maintainability. Use by default for Rails coding, refactoring, debugging, feature implementation, migrations, controller/model changes, and code review tasks so baseline standards stay consistent.
---

# Rails Best Practices Core

Use this as the default baseline for Rails work. It is distilled from 37signals codebases such as Campfire and Fizzy, plus DHH's review patterns.

## Core Defaults

- Prefer clear, explicit code over clever abstractions. Abstractions must earn their keep; if you cannot point to three or more variations that need it, inline it.
- Keep controllers thin and put domain behaviour in models.
- Prefer Rails conventions and built-ins before adding gems.
- Model state and behaviour with domain concepts, not ad hoc flags.
- Scope tenant and user data through ownership boundaries.
- Favour database constraints for hard invariants; validate in Active Record when user-facing error messages are needed.
- Keep interfaces small; do not add public methods that are not used anywhere.
- Prefer write-time computation over expensive read-time composition, such as counter caches, delegated types, precomputed rollups, and `dependent: :delete_all` when callbacks are not needed.
- Use `params.expect(...)` for strong params in modern Rails.
- Let unexpected failures crash. Use bang methods such as `create!` and handle exceptions at boundaries. Only use `!` when a non-bang counterpart exists.
- Fix root causes, not symptoms, such as `enqueue_after_transaction_commit` instead of retry logic for transaction races.
- Ship tests in the same PR as behaviour changes.

## Modelling Patterns

- Model state as records, not booleans. Prefer a `Closure` record with creator and timestamps over `closed: boolean`:

```ruby
has_one :closure, dependent: :destroy
scope :closed, -> { joins(:closure) }
scope :open, -> { where.missing(:closure) }
```

- Slice large models into concerns named for capabilities, such as `Closeable`, `Watchable`, or `Assignable`. Keep each concern cohesive, self-contained, and roughly 50-150 lines.
- Prefer nested modules under the model namespace, such as `Card::Closeable` in `app/models/card/closeable.rb`, for domain slices. Reserve `app/models/concerns/` for genuinely cross-model behaviour.
- Never extract concerns that contain only private methods.
- Put POROs in `app/models/`, not `app/services/`, when they are model-adjacent: presentation objects (`Event::Description`), complex operations (`SystemCommenter`), and view-context bundles (`User::Filtering`).
- Use default lambdas for contextual associations, such as `belongs_to :creator, class_name: "User", default: -> { Current.user }`.
- Use `Current` attributes for request context (`Current.user`, `Current.account`) and cascading setters when one context value resolves another.
- Use callbacks for setup and cleanup, not core business logic. Keep callback counts low.
- Reach for Rails shortcuts: `normalizes`, `store_accessor`, `delegated_type`, `generates_token_for`, string enums, `after_save_commit`, `touch: true`, and `delegate`.
- Use association extensions for bulk domain operations. Put operations like `grant_to` or `revise` on the `has_many` proxy; use `insert_all` for bulk creates.
- Prefer human-friendly URLs. Override `to_param` with a per-tenant number when that fits better than exposing raw IDs or UUIDs.

## Naming

- Treat naming as design. `Closure` beats `CardClose`; `Mention` beats `UserReference`.
- Prefer positive names: `active` over `not_deleted`, `visible` over `not_hidden`.
- Name semantic associations by role, such as `belongs_to :creator, class_name: "User"`, not `belongs_to :user`.
- Prefer domain language over technical phrasing: `quota.depleted?` over `quota.over_limit?`.
- Use business-focused scopes such as `:active`, `:unassigned`, and `:golden`, not SQL-ish names such as `:without_pop`.
- Keep domain language consistent. Do not mix `source`, `resource`, and `container` for one concept.

## REST And Routing

- Treat everything as CRUD. Turn verbs into nouns: close becomes `resource :closure`; publish becomes `resource :publication`. Avoid custom member actions when resource modelling is clearer.
- Use singular `resource` for one-per-parent state.
- Use `scope module:` to group nested controllers, such as `Cards::ClosuresController`.
- Prefer shallow nesting for deep hierarchies.
- Use resource-scoping controller concerns, such as `CardScoped`, to set parent records through the current ownership boundary.
- Use `resolve "Comment"` when polymorphic URL generation should point to a parent with an anchor.
- Let the same controllers serve HTML, Turbo, and JSON via `respond_to` when possible. Do not create a separate API namespace unless the API has distinct semantics.

## Authorisation

- Avoid Pundit and CanCanCan by default. Prefer simple predicate methods on models, such as `card.editable_by?(user)` and `user.can_administer_board?(board)`.
- Controllers enforce access; models define what the permission means.
- Prefer declarative controller macros for authentication posture, such as `allow_unauthenticated_access` and `ensure_can_administer`.

## Dependencies

Before adding a gem, ask whether vanilla Rails can do it and whether 50-150 lines in-repo would be simpler than a dependency. Commonly skipped defaults include Devise, Pundit, ViewComponent, RSpec, FactoryBot, Redis when Solid Queue/Cache/Cable can use the database, service objects, form objects, decorators, GraphQL, SPA frameworks, and Tailwind when the app has a different styling convention.

## Review Priorities

1. Correctness and data safety.
2. Multi-tenant and security boundaries.
3. Maintainability and readability.
4. Performance hot spots.
5. Style and polish.

## Always Flag

- Unscoped record lookups in tenant-aware flows, such as `Comment.find(params[:id])`.
- New dependencies without strong justification.
- In-memory filtering or sorting that belongs in SQL, and `.map(&:name)` where `.pluck(:name)` works.
- Service objects replacing straightforward model methods.
- Non-RESTful custom actions when resource modelling is clearer.
- Boolean state columns where a record would capture who and when.
- Pages with forms using HTTP caching (`fresh_when` or ETags), because stale CSRF tokens cause 422s.
- String status checks (`status == "x"`) when predicate-style APIs are available.
- `validates :x, uniqueness: true` without a backing unique index.
- Helpers depending on implicit instance variables instead of explicit arguments.
- Unescaped interpolation into `html_safe` strings. Escape first: `"<b>#{h(input)}</b>".html_safe`.
- Metaprogramming for two or three cases. Just write the methods.
- Private-only concerns. Inline them.

## Review Output

- Start with the highest-severity findings.
- For each finding, include the issue, impact, concrete fix, and file:line reference.
- Be direct and practical.
- End with either `Ship it` or a short prioritised fix list.
