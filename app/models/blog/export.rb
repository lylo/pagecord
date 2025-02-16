require "zip"

class Blog::Export < ApplicationRecord
  self.table_name = "blog_exports"

  belongs_to :blog

  has_one_attached :file

  enum :status, [ :pending, :in_progress, :completed, :failed ]

  def perform
    in_progress!

    Dir.mktmpdir do |dir|
      export_posts(dir)
      attach_zip_file(dir)
    end

    completed!
  end

  private

    def export_posts(dir)
      blog.posts.find_each do |post|
        export_post_to_html(post, dir)
      end
    end

    def export_post_to_html(post, dir)
      images_dir = File.join(dir, "images")
      FileUtils.mkdir_p(images_dir)

      html = strip_action_text_attachments(post.content.to_s)
      post_content = download_and_replace_images(html, post, images_dir)

      File.open(File.join(dir, "#{post.title_param}.html"), "w") do |file|
        file.write(<<~HTML)
          <!DOCTYPE html>
          <html>
          <head>
            <meta charset="utf-8">
            <title>#{post.display_title}</title>
          </head>
          <body>
        HTML

        file.write("<h1>#{post.title}</h1>") if post.title.present?
        file.write(post_content)
        file.write("</body></html>")
      end
    end

    def strip_action_text_attachments(html)
      doc = Nokogiri::HTML::DocumentFragment.parse(html)

      doc.css("action-text-attachment").each do |attachment|
        if img = attachment.at_css("img")
          figure = img.parent
          figure.replace(img) if figure.name == "figure"
          attachment.replace(img)
        end
      end

      doc.to_html
    end

    def download_and_replace_images(html, post, images_dir)
      post_images_dir = File.join(images_dir, post.token)
      FileUtils.mkdir_p(post_images_dir)

      doc = Nokogiri::HTML::DocumentFragment.parse(html)
      doc.css("img").each do |img|
        src = img["src"]
        next unless src

        safe_filename = sanitized_filename(src)
        local_path = File.join(post_images_dir, safe_filename)

        File.open(local_path, "wb") { |file| file.write(URI.open(src).read) }

        # Rewrite the image src
        img["src"] = "images/#{post.token}/#{safe_filename}"
      end

      doc.to_html
    end

    def sanitized_filename(url)
      decoded_filename = URI.decode_www_form_component(File.basename(url))
      decoded_filename.gsub(/[^0-9A-Za-z.\-]/, "_")
    end

    def attach_zip_file(dir)
      zip_path = File.join(dir, "#{blog.id}_export_#{Time.current.to_i}.zip")

      Zip::File.open(zip_path, Zip::File::CREATE) do |zipfile|
        Dir[File.join(dir, "**", "**")].each do |file|
          next if file == zip_path  # Skip the zip file itself
          zipfile.add(file.sub(dir + "/", ""), file)
        end
      end

      # Attach the zip file to Active Storage
      file.attach(
        io: File.open(zip_path),
        filename: File.basename(zip_path),
        content_type: "application/zip"
      )
    end
end
