require "zip"

class Blog::Export < ApplicationRecord
  self.table_name = "blog_exports"

  belongs_to :blog

  has_one_attached :file

  enum :status, [ :pending, :in_progress, :completed, :failed ]
  enum :format, [ :html, :markdown ]

  def display_format
    html? ? "HTML" : format.titleize
  end

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
      create_index(dir)

      blog.all_posts.find_each do |post|
        export_post(post, dir)
      end
    end

    def create_index(dir)
      if markdown?
        template_path = Rails.root.join("app/views/blog/exports/index.md.erb")
        filename = "index.md"
      else
        template_path = Rails.root.join("app/views/blog/exports/index.html.erb")
        filename = "index.html"
      end

      template = ERB.new(File.read(template_path), trim_mode: "-")

      File.open(File.join(dir, filename), "w") do |file|
        file.write(template.result(binding))
      end
    end

    def export_post(post, dir)
      images_dir = File.join(dir, "images")
      FileUtils.mkdir_p(images_dir)

      stripped_html = Html::StripActionTextAttachments.new.transform(post.content.to_s)

      if markdown?
        @post_content = html_to_markdown(Blog::Export::ImageHandler.new(post, images_dir).process_images(stripped_html))
        template_path = Rails.root.join("app/views/blog/exports/post.md.erb")
        file_extension = "md"
      else
        @post_content = Blog::Export::ImageHandler.new(post, images_dir).process_images(stripped_html)
        template_path = Rails.root.join("app/views/blog/exports/post.html.erb")
        file_extension = "html"
      end

      template = ERB.new(File.read(template_path), trim_mode: "-")

      File.open(File.join(dir, "#{post.slug}.#{file_extension}"), "w") do |file|
        file.write(template.result(binding))
      end
    end

    def html_to_markdown(html)
      ReverseMarkdown.convert(html)
    end

    def attach_zip_file(dir)
      zip_path = File.join(dir, "#{blog.subdomain.parameterize}_export_#{Time.current.to_i}.zip")

      Zip::File.open(zip_path, create: true) do |zipfile|
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
