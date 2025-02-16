require "zip"

class Blog::Export < ApplicationRecord
  self.table_name = "blog_exports"

  belongs_to :blog

  has_one_attached :file

  enum :status, [ :pending, :in_progress, :completed, :failed ]

  def perform
    in_progress!

    begin
      Dir.mktmpdir do |dir|
        export_posts(dir)
        attach_zip_file(dir)
      end
    rescue => e
      Rails.logger.error("Export failed: #{e.message}")
      failed!

      raise e
    else
      completed!
    end
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

      stripped_html = Html::StripActionTextAttachments.new.transform(post.content.to_s)
      post_content = Blog::Export::ImageHandler.new(post, images_dir).process_images(stripped_html)

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

    def attach_zip_file(dir)
      zip_path = File.join(dir, "#{blog.id}_export_#{Time.current.to_i}.zip")

      Zip::File.open(zip_path, Zip::File::CREATE) do |zipfile|
        Dir[File.join(dir, "**", "**")].each do |file|
          next if file == zip_path  # Skip the zip file itself
          zipfile.add(file.sub(dir + "/", ""), file)
        end
      end

      file.attach(
        io: File.open(zip_path),
        filename: File.basename(zip_path),
        content_type: "application/zip"
      )
    end
end
