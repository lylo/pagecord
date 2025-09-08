require "open-uri"
require "nokogiri"
require "cgi"

# Shared helper methods for import scripts
module ImportHelpers
  # Process all img tags in HTML content: download images and create ActionText attachments
  def process_images_to_actiontext(html_content)
    processed_content = Nokogiri::HTML::DocumentFragment.parse(html_content)

    processed_content.css("img").each do |img|
      image_src = img["src"]
      alt_text = img["alt"] || ""
      next unless image_src

      begin
        # Download the image with timeouts
        file = URI.open(image_src,
          open_timeout: 10,    # 10 seconds to establish connection
          read_timeout: 30     # 30 seconds to read the response
        )
        filename = File.basename(URI.parse(image_src).path)
        filename = "image_#{Time.current.to_i}.jpg" if filename.empty? || !filename.include?('.')

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

        # Add caption if alt text exists
        if alt_text && !alt_text.empty?
          trix_attributes[:caption] = alt_text
        end

        attachment_node = %Q(<figure data-trix-attachment="#{CGI.escapeHTML(trix_attributes.to_json)}"></figure>)
        img.replace(attachment_node)
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
