require "zip"
require "json"
require "open-uri"
require "nokogiri"

# Usage: ruby import_blog_archive.rb path/to/blog_archive.zip blog_subdomain
def import_blog_archive(file_path, blog_subdomain)
  # Open the ZIP file
  Zip::File.open(file_path) do |zip_file|
    # Locate the feed.json file in the root of the ZIP
    feed_entry = zip_file.find { |entry| entry.name == "feed.json" }
    unless feed_entry
      puts "feed.json not found in the archive."
      return
    end

    # Parse the feed.json file
    json_data = JSON.parse(feed_entry.get_input_stream.read)

    # Find the correct blog
    blog = Blog.find_by(subdomain: blog_subdomain)
    unless blog
      puts "Blog not found: #{blog_subdomain}. Exiting..."
      return
    end

    # Update the blog title to match the "title" field in the JSON
    blog_title = json_data["title"]
    if blog_title.present?
      blog.update(title: blog_title)
      puts "Updated blog title to: #{blog_title}"
    end

    # Extract the "icon" field and save it to the blog's avatar (ActiveStorage)
    icon_path = json_data["icon"]
    if icon_path.present?
      if icon_path.start_with?("https://")
        # Download the icon from the internet
        begin
          file = URI.open(icon_path)
          blog.avatar.attach(io: file, filename: File.basename(URI.parse(icon_path).path))
          puts "Updated blog avatar with icon from URL: #{icon_path}"
        rescue OpenURI::HTTPError => e
          puts "Failed to download icon from URL: #{icon_path}. Error: #{e.message}"
        end
      else
        # Locate the icon file in the ZIP
        icon_entry = zip_file.find { |entry| entry.name == icon_path.sub(%r{^/}, "") }
        if icon_entry
          # Remove the existing avatar if it exists
          blog.avatar.purge if blog.avatar.attached?

          # Attach the new avatar
          file = StringIO.new(icon_entry.get_input_stream.read)
          blog.avatar.attach(io: file, filename: File.basename(icon_path))
          puts "Updated blog avatar with icon from archive: #{icon_path}"
        else
          puts "Icon file #{icon_path} not found in the archive. Skipping avatar update."
        end
      end
    end

    json_data["items"].each do |item|
      # Extract post attributes
      title = item["title"]
      content_html = item["content_html"]
      content_text = item["content_text"]
      published_at = item["date_published"]

      # Reconstruct content_html by appending <img> tags from content_text
      if content_html.include?("<!-- raw HTML omitted -->")
        # Extract <img> tags from content_text
        img_tags = content_text.scan(/<img[^>]*>/i).join("\n")
        # Append the <img> tags to content_html
        content_html = content_html.gsub("<!-- raw HTML omitted -->", img_tags)
      end

      # Create and save the Post object
      post = blog.posts.new(
        title: title,
        published_at: published_at,
        content: content_html # Temporarily assign content_html
      )

      if post.save
        puts "Successfully created post: #{title}"
      else
        puts "Failed to create post: #{title}"
        puts post.errors.full_messages
        next
      end

      # Process content_html and convert <img> tags to ActionText attachments
      processed_content = Nokogiri::HTML::DocumentFragment.parse(content_html)
      processed_content.css("img").each do |img|
        image_path = img["src"] # e.g., "uploads/2024/whatsapp-image-2024-08-21-at-09.47.54.jpeg"

        # Locate the image file in the ZIP
        image_entry = zip_file.find { |entry| entry.name == image_path }
        unless image_entry
          puts "Image file #{image_path} not found in the archive. Skipping image."
          next
        end

        puts "Processing image: #{image_path}"

        # Extract the image file and attach it to the post
        file = StringIO.new(image_entry.get_input_stream.read)
        post.attachments.attach(io: file, filename: File.basename(image_path))

        # Ensure the attachment is saved to the database
        post.attachments.reload

        # Replace the <img> tag with ActionText attachment
        attachment = post.attachments.last
        img.replace(ActionText::Attachment.from_attachable(attachment).to_html)
      end

      # Update the post's content with the processed content
      post.update(content: processed_content.to_html)
    end
  end
end

# Run the script if executed directly
if __FILE__ == $PROGRAM_NAME
  if ARGV.length != 2
    puts "Usage: bundle exec rails runner import_blog_archive.rb path/to/blog_archive.zip blog_subdomain"
    exit 1
  end

  file_path = ARGV[0]
  blog_subdomain = ARGV[1]

  unless File.exist?(file_path)
    puts "File not found: #{file_path}"
    exit 1
  end

  import_blog_archive(file_path, blog_subdomain)
end
