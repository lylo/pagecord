require "json"
require "open-uri"
require "nokogiri"

# Usage: ruby import_ghost_json.rb path/to/ghost_export.json blog_subdomain ghost_url
def import_ghost_json(file_path, blog_subdomain, ghost_url)
  # Parse the Ghost JSON file
  json_data = JSON.parse(File.read(file_path))

  # Find the correct blog
  blog = Blog.find_by(subdomain: blog_subdomain)
  unless blog
    puts "Blog not found: #{blog_subdomain}. Exiting..."
    return
  end

  # Extract posts data from the JSON structure
  posts_data = json_data.dig("db", 0, "data", "posts") || []

  # Filter to only include posts (not pages) and published status
  posts_to_import = posts_data.select do |post|
    post["type"] == "post" && post["status"] == "published"
  end

  puts "Found #{posts_to_import.length} posts to import"

  posts_to_import.each do |post_data|
    # Extract post attributes from Ghost format
    title = post_data["title"]
    html_content = post_data["html"]
    plaintext_content = post_data["plaintext"]
    published_at = post_data["published_at"]
    excerpt = post_data["custom_excerpt"]
    feature_image = post_data["feature_image"]

    # Check if post already exists by title
    existing_post = blog.posts.find_by(title: title)
    if existing_post
      puts "Skipping duplicate post: #{title}"
      next
    end

    # Replace __GHOST_URL__ references with the actual ghost URL
    if feature_image
      feature_image = feature_image.gsub("__GHOST_URL__", ghost_url)
    end

    # Determine content to use (html -> plaintext -> custom_excerpt)
    content_to_use = nil
    content_needs_feature_image = false

    if html_content.present?
      content_to_use = html_content.gsub("__GHOST_URL__", ghost_url)
    elsif plaintext_content.present?
      # Convert plaintext to HTML and add feature image if present
      content_to_use = Html::PlainTextToHtml.call(plaintext_content)
      content_needs_feature_image = true
    elsif excerpt.present?
      content_to_use = "<p>#{excerpt}</p>"
      content_needs_feature_image = true
    end

    # Add feature image to content if needed
    if content_needs_feature_image && feature_image.present?
      feature_img_tag = "<img src=\"#{feature_image}\" alt=\"#{title}\" />"
      content_to_use = "#{feature_img_tag}\n#{content_to_use}"
    end

    # Create and save the Post object
    post = blog.posts.new(
      title: title,
      published_at: published_at,
      content: content_to_use
    )

    if post.save
      puts "Successfully created post: #{title}"
    else
      puts "Failed to create post: #{title}"
      puts post.errors.full_messages
      next
    end

    # Process HTML content for images and convert them to ActionText attachments
    if content_to_use.present?
      processed_content = Nokogiri::HTML::DocumentFragment.parse(content_to_use)
      processed_content.css("img").each do |img|
        image_src = img["src"]

        # Skip if no src or if it's already processed
        next unless image_src

        # Replace __GHOST_URL__ in image src if present
        image_src = image_src.gsub("__GHOST_URL__", ghost_url)

        # Skip if it's already an ActionText attachment or data URL
        next if image_src.include?("rails/active_storage") || image_src.start_with?("data:")

        begin
          puts "Processing image: #{image_src}"

          # Download the image
          file = URI.open(image_src)
          post.attachments.attach(io: file, filename: File.basename(URI.parse(image_src).path))

          # Ensure the attachment is saved
          post.attachments.reload

          # Replace the <img> tag with ActionText attachment
          attachment = post.attachments.last
          img.replace(ActionText::Attachment.from_attachable(attachment).to_html)
        rescue => e
          puts "Failed to process image #{image_src}: #{e.message}"
          # Keep the original img tag if download fails
        end
      end

      # Update the post's content with processed attachments
      post.update(content: processed_content.to_html)
    end
  end

  puts "Import completed. Imported #{posts_to_import.length} posts."
end

# Run the script if executed directly
if __FILE__ == $PROGRAM_NAME
  if ARGV.length != 3
    puts "Usage: bundle exec rails runner import_ghost_json.rb path/to/ghost_export.json blog_subdomain ghost_url"
    puts "Example: bundle exec rails runner import_ghost_json.rb ghost_export.json myblog https://your.ghostdomain.com"
    exit 1
  end

  file_path = ARGV[0]
  blog_subdomain = ARGV[1]
  ghost_url = ARGV[2]

  unless File.exist?(file_path)
    puts "File not found: #{file_path}"
    exit 1
  end

  import_ghost_json(file_path, blog_subdomain, ghost_url)
end
