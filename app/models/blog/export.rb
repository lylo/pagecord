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
      create_index_html(dir)

      blog.posts.find_each do |post|
        export_post_to_html(post, dir)
      end
    end

    def create_index_html(dir)
      template_path = Rails.root.join("app/views/blog/exports/index.html.erb")
      template = ERB.new(File.read(template_path), trim_mode: "-")

      File.open(File.join(dir, "index.html"), "w") do |file|
        file.write(template.result(binding))
      end
    end

    def export_post_to_html(post, dir)
      images_dir = File.join(dir, "images")
      FileUtils.mkdir_p(images_dir)

      stripped_html = Html::StripActionTextAttachments.new.transform(post.content.to_s)
      @post_content = Blog::Export::ImageHandler.new(post, images_dir).process_images(stripped_html)

      template_path = Rails.root.join("app/views/blog/exports/post.html.erb")
      template = ERB.new(File.read(template_path), trim_mode: "-")

      File.open(File.join(dir, "#{post.to_title_param}.html"), "w") do |file|
        file.write(template.result(binding))
      end
    end

    def attach_zip_file(dir)
      zip_path = File.join(dir, "#{blog.name.parameterize}_export_#{Time.current.to_i}.zip")

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
