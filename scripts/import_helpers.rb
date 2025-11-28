require "open-uri"
require "nokogiri"
require "cgi"

# Shared helper methods for import scripts
module ImportHelpers
  # Process all img tags in HTML content: download images and create ActionText attachments
  def process_images_to_actiontext(html_content, assets_root: nil, dry_run: false)
    processed_content = Nokogiri::HTML::DocumentFragment.parse(html_content)

    processed_content.css("img").each do |img|
      image_src = img["src"]
      alt_text = img["alt"] || ""
      next unless image_src

      # Skip data URI images (commonly used as placeholders for lazy loading)
      if image_src.start_with?("data:")
        # Remove the placeholder image entirely
        parent_figure = img.ancestors("figure").first
        if parent_figure
          parent_figure.remove
        else
          img.remove
        end
        next
      end

      begin
        # In dry run mode, just verify file exists but don't upload
        if dry_run
          if assets_root && image_src.start_with?('/')
            decoded_src = CGI.unescape(image_src)
            local_path = File.join(assets_root, decoded_src)
            unless File.exist?(local_path)
              raise "Local file not found: #{local_path}"
            end
          end
          # Skip actual processing in dry run
          next
        end

        # Handle local file paths (starting with /) vs remote URLs
        if assets_root && image_src.start_with?('/')
          # Local file path - resolve relative to assets_root
          # Decode URL-encoded characters (e.g., %20 -> space)
          decoded_src = CGI.unescape(image_src)
          local_path = File.join(assets_root, decoded_src)
          unless File.exist?(local_path)
            raise "Local file not found: #{local_path}"
          end
          file = File.open(local_path)
          filename = File.basename(local_path)
        else
          # Remote URL - download with timeouts
          file = URI.open(image_src,
            open_timeout: 10,    # 10 seconds to establish connection
            read_timeout: 30     # 30 seconds to read the response
          )
          filename = File.basename(URI.parse(image_src).path)
          filename = "image_#{Time.current.to_i}.jpg" if filename.empty? || !filename.include?('.')
        end

        # Create blob
        blob = ActiveStorage::Blob.create_and_upload!(io: file, filename: filename)

        # Create ActionText attachment with optional caption
        url = Rails.application.routes.url_helpers.rails_blob_path(blob, only_path: true)
        trix_attributes = {
          sgid: blob.attachable_sgid,
          contentType: blob.content_type,
          filename: blob.filename.to_s,
          filesize: blob.byte_size,
          previewable: blob.previewable?,
          url: url
        }

        # Check if img is inside a figure with figcaption
        parent_figure = img.ancestors('figure').first
        caption_text = nil

        if parent_figure
          # Extract caption from figcaption if it exists
          figcaption = parent_figure.at_css('figcaption')
          caption_text = figcaption&.text&.strip
        end

        # Use figcaption if available, otherwise fall back to alt text
        caption_text = alt_text if caption_text.nil? || caption_text.empty?

        # Add caption if it exists
        if caption_text && !caption_text.empty?
          trix_attributes[:caption] = caption_text
        end

        attachment_node = %Q(<figure data-trix-attachment="#{CGI.escapeHTML(trix_attributes.to_json)}"></figure>)

        # If inside a figure, replace the entire figure; otherwise just replace the img
        if parent_figure
          parent_figure.replace(attachment_node)
        else
          img.replace(attachment_node)
        end
      rescue => e
        raise "Failed to process image #{image_src}: #{e.message}"
      end
    end

    processed_content.to_html
  end

  # Check if a post already exists by title (case-insensitive) or slug
  def post_exists?(blog, title)
    return false unless title

    # Check for exact title match (case-insensitive)
    existing_post = blog.all_posts.where("LOWER(title) = LOWER(?)", title).first
    return existing_post if existing_post

    # Check for slug collision using the same logic as the model
    simple_slug = title.parameterize.truncate(100, omission: "").gsub(/-+\z/, "")
    if simple_slug.present?
      existing_post = blog.all_posts.find_by(slug: simple_slug)
    end

    existing_post
  end

  # Clean and normalize tag text for import
  def clean_tag(tag_text)
    tag_text.strip.downcase.gsub(/\s+/, '-').gsub(/[^a-z0-9\-]/, '')
  end

  # Parse datetime string with fallback to current time
  def parse_datetime(datetime_string, fallback_message: nil)
    return Time.current unless datetime_string.present?

    begin
      Time.parse(datetime_string)
    rescue ArgumentError
      puts fallback_message if fallback_message
      Time.current
    end
  end
end
