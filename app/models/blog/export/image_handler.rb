class Blog::Export::ImageHandler
  def initialize(post, root_dir)
    @post = post
    @post_images_dir = File.join(root_dir, @post.token)
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
    end

    def sanitized_filename(url)
      decoded_filename = URI.decode_www_form_component(File.basename(url))
      decoded_filename.gsub(/[^0-9A-Za-z.\-]/, "_")
    end

    def download_image(src, local_path)
      File.open(local_path, "wb") { |file| file.write(URI.open(src).read) }
    end

    def update_img_src(img, safe_filename)
      img["src"] = "images/#{@post.token}/#{safe_filename}"
    end
end
