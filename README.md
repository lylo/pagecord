# Pagecord

Publish your writing effortlessly. All you need is email.

[https://pagecord.com](https://pagecord.com)

![](https://github.com/lylo/pagecord/actions/workflows/ci.yml/badge.svg)

## Development

To set up your development environment, install Ruby 3.3+ using [HomeBrew](https://brew.sh/) and [rbenv](https://github.com/rbenv/rbenv).

Then checkout this repository and run:

```bash
git clone https://github.com/lylo/pagecord.git
cd pagecord
bundle install
```

### Setting up the database

Before you run the app in development, first set up the database:

```bash
rails db:setup
```

### Install Redis

Pagecord uses Sidekiq, which uses Redis.

```
brew install redis
```

### Running the app

To start the app, run:

```bash
bin/dev
```

You can view the app in your browser at [http://localhost:3000](http://localhost:3000), but it's currently configred to use `lvh.me`. You can view individual blogs on their respective subdomains, e.g. [http://joel.lvh.me:3000](http://joel.lvh.me:3000).

### Running the tests

The app is tested using the Rails standard, minitest. To run the tests, use the following commands:

```bash
bin/rails test
bin/rails test:system
```

## Tags Feature

Pagecord includes a comprehensive tagging system that allows users to organize their blog posts with tags. The tags feature is built using modern Rails patterns with Turbo and Stimulus for a smooth user experience.

### Key Features

- **Interactive Tag Input**: Add and remove tags with an intuitive interface using keyboard shortcuts (Enter/Tab to add, Backspace to remove)
- **Tag Validation**: Tags are automatically normalized and validated (alphanumeric characters and hyphens only, max 50 characters)
- **Tag Filtering**: Filter posts by clicking on tags in both admin and public blog views
- **PostgreSQL Arrays**: Efficient storage using PostgreSQL array fields with GIN indexing for fast queries
- **Reusable Components**: Shared partials and Stimulus controllers for consistent tag display across the app

### Implementation Details

#### Database Schema
Tags are stored as a PostgreSQL array field (`tag_list`) on the posts table with a GIN index for optimal performance:

```ruby
add_column :posts, :tag_list, :text, array: true, default: []
add_index :posts, :tag_list, using: :gin
```

#### Taggable Concern
The `Taggable` concern provides:
- `tags_string` getter/setter for form input
- Tag parsing from comma-separated strings
- Tag normalization (downcase, strip, alphanumeric + hyphens)
- Validation (presence, format, length)
- Query methods (`tagged_with`, `tags_containing`)

#### Frontend Components
- **Stimulus Controller**: `tags-input-controller.js` handles interactive tag management
- **Shared Partial**: `_tags.html.erb` provides consistent tag display with optional linking
- **Form Integration**: Hidden tags section accessible via dropdown menu

#### Tag Filtering
Both admin (`/app/posts`) and public blog views support tag filtering:
- Click any tag to filter posts
- Filter indicators show active tag filters
- Clear filters option available

### Usage Examples

#### Adding Tags to Posts
```erb
<!-- In post forms -->
<%= form.hidden_field :tags_string, data: { tags_input_target: "input" } %>
<div data-controller="tags-input" data-tags-input-initial-value="<%= post.tags_string %>">
  <!-- Interactive tag interface -->
</div>
```

#### Displaying Tags
```erb
<!-- Clickable tags -->
<%= render "shared/tags", post: post, linkable: true %>

<!-- Static tags -->
<%= render "shared/tags", post: post, linkable: false %>
```

#### Querying Posts by Tags
```ruby
# Find posts with specific tag
Post.tagged_with("ruby")

# Find posts with any of multiple tags
Post.tagged_with(["ruby", "rails"])

# Find posts with tags containing text
Post.tags_containing("web")
```

### Testing
Comprehensive test coverage includes:
- **Taggable Concern**: 16 tests covering tag parsing, validation, normalization, and querying
- **Controller Integration**: Tests for tag filtering and form processing
- **Model Integration**: Tests for Post model with Taggable concern

Run tag-specific tests:
```bash
rails test test/models/concerns/taggable_test.rb
rails test test/controllers/app/posts_controller_test.rb
rails test test/controllers/blogs/posts_controller_test.rb
```

## Processing an email locally

Sometimes you'll need to debug emails. To do this, save the .eml file(s) to a folder
such as `tmp/emails`.

You can then run the following command which will parse all the .eml files in that
folder and create posts for the first user account in the seed data (`joel@pagecord.com`).

```bash
DIR=tmp/emails rake email:load
```

## More info

Read about [the Pagecord architecture](architecture.md) or [making contributions](CONTRIBUTIONS.md).

Follow the [Pagecord blog](https://pagecord.com/blog).

<a href="https://www.buymeacoffee.com/heyolly" target="_blank"><img src="https://cdn.buymeacoffee.com/buttons/v2/default-red.png" alt="Buy Me A Coffee" style="height: 50px !important;width: 178px !important;" ></a>