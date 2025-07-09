# Dreamwidth Import Script

This script imports blog posts from a Dreamwidth HTML dump into a Pagecord blog.

## Requirements

- A Dreamwidth HTML export folder containing:
  - `entries/` - HTML files for each blog post
  - `images/` (optional) - Images referenced in posts
  - `userpics/` (optional) - User profile pictures

## Usage

```bash
# Basic import
rails runner scripts/import_dreamwidth_posts.rb /path/to/dreamwidth-dump-html your_blog_subdomain

# Dry run (preview what would be imported)
rails runner scripts/import_dreamwidth_posts.rb /path/to/dreamwidth-dump-html your_blog_subdomain --dry-run
```

## What the script does

1. **Extracts post title** from `<h3 class="entry-title">`
2. **Extracts post date** from `<span class="datetime">` within the header
3. **Extracts content** from `<div class="entry-content">`
4. **Processes images**:
   - Converts relative image paths (e.g. `../images/photo.jpg`) to ActionText attachments
   - Uploads image files to Active Storage
   - Leaves external URLs unchanged
5. **Extracts tags** from `<div class="tag"><ul><li>` elements
   - Handles hierarchical tags (e.g. "hobbies: gaming" becomes "gaming")
6. **Creates Pagecord posts** with the extracted data
7. **Prevents duplicates** by checking existing posts with same title/date

## Features

- **Dry run mode**: Preview imports without making changes
- **Duplicate detection**: Skips posts that already exist
- **Image processing**: Converts relative images to embedded attachments
- **Tag extraction**: Handles hierarchical tag structures
- **Error handling**: Continues processing even if individual posts fail
- **Progress reporting**: Shows detailed status for each processed file

## Example Output

```
Dreamwidth Import for blog: @myblog
Entries path: /Users/olly/Downloads/dreamwidth-dump-html/entries
Images path: /Users/olly/Downloads/dreamwidth-dump-html/images

Found 150 entry files to process

[1/150] Processing entry-1.html
  ✅ Created: My First Post
     Tags: [personal, blogging]
     Date: 2007-11-15 10:22

[2/150] Processing entry-2.html
  SKIP: Post already exists (Another Post - 2007-11-16)

==================================================
✅ Import completed!
Created: 148 posts
Skipped: 2 posts
Errors: 0 posts
==================================================
```

## Notes

- The script preserves original publication dates
- Images are uploaded to your Pagecord storage
- External image URLs are left unchanged
- Cross-references to other entries become placeholder links
- The script is safe to run multiple times (duplicate detection)

## Troubleshooting

If you get permission errors or missing files:
1. Ensure the Dreamwidth export folder is properly extracted
2. Check that your blog subdomain exists in Pagecord
3. Run with `--dry-run` first to preview the import
4. Check Rails logs for detailed error messages
