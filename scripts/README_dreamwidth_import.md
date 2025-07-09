# Dreamwidth Import Script

This script imports blog posts from a Dreamwidth HTML dump into a Pagecord blog.

## Requirements

- A Dreamwidth HTML export folder containing:
  - `entries/` - HTML files for each blog post
  - `images/` (optional) - Images referenced in posts
  - `userpics/` (optional) - User profile pictures

## Usage

```bash
rails runner scripts/import_dreamwidth_posts.rb <dreamwidth_folder> <blog_subdomain> [options]

# Examples:
rails runner scripts/import_dreamwidth_posts.rb /path/to/dreamwidth-dump-html myblog
rails runner scripts/import_dreamwidth_posts.rb /path/to/dreamwidth-dump-html myblog --dry-run
rails runner scripts/import_dreamwidth_posts.rb /path/to/dreamwidth-dump-html myblog --skip-images
rails runner scripts/import_dreamwidth_posts.rb /path/to/dreamwidth-dump-html myblog --dry-run --skip-images
```

**Options:**
- `--dry-run` - Preview what would be imported without making changes
- `--skip-images` - Import text content only, skip image processing

## What the script does

1. **Extracts post title** from `<h3 class="entry-title">`
2. **Extracts post date** from `<span class="datetime">` within the header
3. **Extracts content** from `<div class="entry-content">`
4. **Processes images** (when `--skip-images` is not used):
   - Converts relative image paths (e.g. `../images/photo.jpg`) to ActionText attachments
   - Searches for images in subdirectories (e.g. `images/2023-06/`)
   - Uploads image files to Active Storage using proper MIME type detection
   - Leaves external URLs unchanged
5. **Extracts tags** from `<div class="tag"><ul><li>` elements
   - Handles hierarchical tags (e.g. "hobbies: gaming" becomes "gaming")
   - Sanitizes tags to use only allowed characters (alphanumeric, hyphens, underscores)
   - Converts to lowercase and normalizes whitespace
6. **Creates Pagecord posts** with the extracted data
   - Validates post content, title, and slug format
   - Generates URL-friendly slugs that allow underscores and hyphens
7. **Prevents duplicates** by checking:
   - Posts with same title and publication date
   - Posts with identical content (after processing)

## Features

- **Dry run mode**: Preview imports without making changes (`--dry-run`)
- **Skip images mode**: Import text content only, skip image processing (`--skip-images`)
- **Robust duplicate detection**: Checks both title/date and content similarity
- **Smart image processing**:
  - Handles images in subdirectories (e.g. `images/2023-06/`)
  - Proper MIME type detection for all image formats
  - Converts relative paths to ActionText attachments
- **Advanced tag extraction**:
  - Handles hierarchical tag structures
  - Sanitizes tags to valid format (alphanumeric, hyphens, underscores)
  - Normalizes case and whitespace
- **Comprehensive validation**: Validates posts, slugs, and content before saving
- **Error handling**: Continues processing even if individual posts fail
- **Detailed progress reporting**: Shows status, tags, dates, and error details

## Example Output

```
Dreamwidth Import for blog: @myblog
[DRY RUN] [SKIP IMAGES] Entries path: /Users/olly/Downloads/dreamwidth-dump-html/entries

Found 150 entry files to process

[1/150] Processing entry-1.html
  ✅ Created: My First Post
     Tags: [personal, blogging]
     Date: 2007-11-15 10:22
     Slug: my-first-post

[2/150] Processing entry-2.html
  SKIP: Post already exists (Another Post - 2007-11-16)

[3/150] Processing entry-3.html
  SKIP: Duplicate content found for: Photo Gallery

[4/150] Processing entry-4.html
  ✅ Created: Weekend Adventures
     Tags: [travel, hiking, photography]
     Date: 2007-11-17 14:30
     Slug: weekend-adventures
     Images: 3 processed

==================================================
✅ Import completed!
Created: 148 posts
Skipped: 2 posts
Errors: 0 posts
==================================================
```

## Notes

- The script preserves original publication dates from Dreamwidth
- Images are uploaded to your Pagecord Active Storage and properly embedded as ActionText attachments
- External image URLs (http/https) are left unchanged
- Cross-references to other entries become placeholder links
- The script is safe to run multiple times thanks to robust duplicate detection
- Slugs are generated following Pagecord's validation rules (lowercase, alphanumeric, hyphens, underscores)
- Tags are sanitized to use only valid characters and converted to lowercase
- Use `--skip-images` if you want text-only imports or if images are missing/corrupted

## Advanced Usage

### Checking imported tags
After import, you can check all unique tags for your blog in the Rails console:

```ruby
# Replace 'your_subdomain' with your actual blog subdomain
blog = Blog.find_by(subdomain: 'your_subdomain')
all_tags = blog.posts.flat_map(&:tag_list).uniq.sort
puts "Total unique tags: #{all_tags.count}"
all_tags.each { |tag| puts "- #{tag}" }
```

## Troubleshooting

### Common Issues

**Permission errors or file not found:**
1. Ensure the Dreamwidth export folder is properly extracted
2. Move the export folder to your home directory if needed (e.g., `/Users/yourusername/dreamwidth-dump-html`)
3. Check file permissions: `ls -la /path/to/dreamwidth-dump-html`

**Blog not found:**
1. Verify your blog subdomain exists: `Blog.pluck(:subdomain)` in Rails console
2. Use the exact subdomain (case-sensitive)

**Image import issues:**
1. Use `--skip-images` to import text content only
2. Check that image files exist in the `images/` subdirectory
3. Look for images in dated subdirectories (e.g., `images/2023-06/`)

**Tag or validation errors:**
1. Run with `--dry-run` first to preview the import
2. Check Rails logs for detailed validation error messages
3. Some posts may have content that doesn't meet Pagecord's validation requirements

### Running Outside VS Code
If you encounter issues with VS Code's integrated terminal, try running the script from a regular terminal:

```bash
cd /path/to/pagecord
rails runner scripts/import_dreamwidth_posts.rb /path/to/dreamwidth-dump-html your_blog_subdomain --dry-run
```

### Getting Help
- Use `--dry-run` to preview imports safely
- Check Rails development logs for detailed error messages
- Verify your Dreamwidth export structure matches the expected format
