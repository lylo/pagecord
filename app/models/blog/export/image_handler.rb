class Blog::Export::ImageHandler
  def initialize(post, root_dir)
    @post = post
    @post_images_dir = File.join(root_dir, @post.slug)
  end

  def process_images(html)
    doc = Nokogiri::HTML::DocumentFragment.parse(html)
    doc.css("img").each do |img|
      process_image(img)
    end
    doc.to_html
  end

  private

    def process_image(img)
      src = img["src"]
      return unless src

      FileUtils.mkdir_p(@post_images_dir)
      safe_filename = sanitized_filename(src)
      local_path = File.join(@post_images_dir, safe_filename)

      download_image(src, local_path)
      update_img_src(img, safe_filename)
    rescue StandardError => e
      message = "Blog::Export::ImageHandler. Unable to process image #{src} for post #{@post.slug}: #{e.message}"
      Sentry.capture_message(message)
      Rails.logger.error message
    end

    def sanitized_filename(url)
      decoded_filename = URI.decode_www_form_component(File.basename(url))
      decoded_filename.gsub(/[^0-9A-Za-z.\-]/, "_")
    end

    def download_image(src, local_path)
      # Extract original URL if it's a Cloudflare CDN image URL
      actual_src = extract_original_url(src)
      Rails.logger.info "Blog::Export::ImageHandler. Downloading image from post #{@post.slug}: #{actual_src} to #{local_path}"
      File.open(local_path, "wb") { |file| file.write(URI.open(actual_src).read) }
    end

    def extract_original_url(src)
      # Extract original URL from Cloudflare CDN image URLs like:
      # https://pagecord.com/cdn-cgi/image/width=1600,height=1200,format=webp,quality=90/https://storage.pagecord.com/78v1ct1yskcl66bzrl5zf8bz2rpw
      src.gsub(%r{https://pagecord\.com/cdn-cgi/image/[^/]+/}, "")
    end

    def update_img_src(img, safe_filename)
      img["src"] = "images/#{@post.slug}/#{safe_filename}"
    end
end
