class Blog::Export::ImageHandler
  def initialize(post, root_dir)
    @post = post
    @post_images_dir = File.join(root_dir, @post.slug)
    @filenames = {}
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
      Rails.logger.warn "Blog::Export::ImageHandler. Unable to process image #{src} for post #{@post.slug} on blog #{@post.blog.subdomain}: #{e.class} - #{e.message}"
    end

    def sanitized_filename(url)
      key = File.basename(url)
      filename = uploaded_filename(key) || URI.decode_www_form_component(key)

      claim(sanitize(filename), key)
    end

    # Our images are served under their ActiveStorage key, which carries no
    # extension, so an exported file can't be opened without one. The name the
    # image was uploaded under has it, and reads better besides. Nil for images
    # hosted elsewhere, whose URLs already end in a filename.
    def uploaded_filename(key)
      ActiveStorage::Blob.find_by(key: key)&.filename&.to_s
    end

    def sanitize(filename)
      filename.gsub(/[^0-9A-Za-z.\-]/, "_")
    end

    # Two images in one post can share an uploaded filename, so the second to
    # claim it is suffixed with its storage key, which is unique.
    def claim(filename, key)
      filename = "#{File.basename(filename, '.*')}-#{key}#{File.extname(filename)}" if claimed_by_another?(filename, key)
      @filenames[filename] = key

      filename
    end

    def claimed_by_another?(filename, key)
      @filenames.fetch(filename, key) != key
    end

    def download_image(src, local_path)
      actual_src = extract_original_url(src)
      Rails.logger.info "Blog::Export::ImageHandler. Downloading image from post #{@post.slug}: #{actual_src} to #{local_path}"

      attempts = 0
      max_retries = 3

      begin
        attempts += 1
        URI.open(actual_src, read_timeout: 30, redirect: true) do |remote_file|
          File.open(local_path, "wb") { |file| file.write(remote_file.read) }
        end
      rescue StandardError => e
        if attempts < max_retries && !client_error?(e)
          wait_time = attempts * 2
          Rails.logger.warn "Blog::Export::ImageHandler. Retry #{attempts}/#{max_retries} for #{actual_src}: #{e.message}. Waiting #{wait_time}s..."
          sleep(wait_time)
          retry
        else
          raise
        end
      end
    end

    def client_error?(error)
      error.is_a?(OpenURI::HTTPError) && error.io.status.first.to_i.in?(400..499)
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
