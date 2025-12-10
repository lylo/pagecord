require "open-uri"
require "nokogiri"
require "cgi"

# Shared helper methods for import scripts
module ImportHelpers
  include ActionView::Helpers::NumberHelper

  # Process all img and video tags in HTML content: download media and create ActionText attachments
  # If skip_on_error is true, failed downloads will leave the original tag intact instead of raising
  def process_images_to_actiontext(html_content, assets_root: nil, dry_run: false, skip_on_error: false)
    processed_content = Nokogiri::HTML::DocumentFragment.parse(html_content)

    # Process images
    processed_content.css("img").each do |img|
      process_image(img, assets_root: assets_root, dry_run: dry_run, skip_on_error: skip_on_error)
    end

    # Process videos
    processed_content.css("video").each do |video|
      process_video(video, assets_root: assets_root, dry_run: dry_run, skip_on_error: skip_on_error)
    end

    processed_content.to_html
  end

  private

    def process_image(img, assets_root:, dry_run:, skip_on_error:)
      image_src = img["src"]
      alt_text = img["alt"] || ""
      return unless image_src

      # Skip data URI images (commonly used as placeholders for lazy loading)
      if image_src.start_with?("data:")
        parent_figure = img.ancestors("figure").first
        parent_figure ? parent_figure.remove : img.remove
        return
      end

      begin
        return if dry_run && !local_file?(image_src, assets_root)

        if dry_run
          verify_local_file(image_src, assets_root)
          return
        end

        file, filename = download_or_open_file(image_src, assets_root: assets_root, type: "image")
        blob = ActiveStorage::Blob.create_and_upload!(io: file, filename: filename)
        puts "    Stored as: #{blob.key} (#{number_to_human_size(blob.byte_size)})"

        attachment_node = build_attachment_node(blob, img, alt_text)
        replace_with_attachment(img, attachment_node)
      rescue => e
        handle_media_error(e, image_src, "image", skip_on_error)
      end
    end

    def process_video(video, assets_root:, dry_run:, skip_on_error:)
      # Get video source - either from src attribute or from <source> child
      source = video.at_css("source")
      video_src = video["src"] || source&.[]("src")
      return unless video_src

      begin
        return if dry_run && !local_file?(video_src, assets_root)

        if dry_run
          verify_local_file(video_src, assets_root)
          return
        end

        file, filename = download_or_open_file(video_src, assets_root: assets_root, type: "video")
        blob = ActiveStorage::Blob.create_and_upload!(io: file, filename: filename)
        puts "    Stored as: #{blob.key} (#{number_to_human_size(blob.byte_size)})"

        # Build video attachment node
        url = Rails.application.routes.url_helpers.rails_blob_path(blob, only_path: true)
        trix_attributes = {
          sgid: blob.attachable_sgid,
          contentType: blob.content_type,
          filename: blob.filename.to_s,
          filesize: blob.byte_size,
          previewable: blob.previewable?,
          url: url
        }
        attachment_node = %Q(<figure data-trix-attachment="#{CGI.escapeHTML(trix_attributes.to_json)}"></figure>)
        video.replace(attachment_node)
      rescue => e
        handle_media_error(e, video_src, "video", skip_on_error)
      end
    end

    def local_file?(src, assets_root)
      assets_root && src.start_with?('/')
    end

    def verify_local_file(src, assets_root)
      return unless local_file?(src, assets_root)
      decoded_src = CGI.unescape(src)
      local_path = File.join(assets_root, decoded_src)
      raise "Local file not found: #{local_path}" unless File.exist?(local_path)
    end

    def download_or_open_file(src, assets_root:, type:)
      if local_file?(src, assets_root)
        decoded_src = CGI.unescape(src)
        local_path = File.join(assets_root, decoded_src)
        raise "Local file not found: #{local_path}" unless File.exist?(local_path)
        filename = File.basename(local_path)
        puts "  Uploading local #{type}: #{filename}"
        [ File.open(local_path), filename ]
      else
        filename = File.basename(URI.parse(src).path)
        filename = "#{type}_#{Time.current.to_i}.#{type == 'video' ? 'mp4' : 'jpg'}" if filename.empty? || !filename.include?('.')
        puts "  Downloading #{type}: #{filename}"
        file = URI.open(src,
          open_timeout: 10,
          read_timeout: type == "video" ? 120 : 30  # Longer timeout for videos
        )
        [ file, filename ]
      end
    end

    def build_attachment_node(blob, img, alt_text)
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
      caption_text = parent_figure&.at_css('figcaption')&.text&.strip
      caption_text = alt_text if caption_text.nil? || caption_text.empty?
      trix_attributes[:caption] = caption_text if caption_text && !caption_text.empty?

      %Q(<figure data-trix-attachment="#{CGI.escapeHTML(trix_attributes.to_json)}"></figure>)
    end

    def replace_with_attachment(img, attachment_node)
      parent_figure = img.ancestors('figure').first
      parent_figure ? parent_figure.replace(attachment_node) : img.replace(attachment_node)
    end

    def handle_media_error(error, src, type, skip_on_error)
      if skip_on_error
        puts "  Warning: Could not download #{type} #{src}, keeping original URL: #{error.message}"
      else
        raise "Failed to process #{type} #{src}: #{error.message}"
      end
    end

  public

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
