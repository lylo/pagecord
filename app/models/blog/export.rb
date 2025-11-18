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

      posts_to_export = blog.all_posts
      posts_to_export = posts_to_export.where.not(id: blog.home_page_id) if blog.has_custom_home_page?
      posts_to_export.find_each do |post|
        export_post(post, dir)
      end
    end

    def create_index(dir)
      if blog.has_custom_home_page?
        export_post(blog.home_page, dir, filename: "index")
        create_posts_list(dir, filename: "posts")
      else
        create_posts_list(dir, filename: "index")
      end
    end

    def create_posts_list(dir, filename:)
      extension = markdown? ? "md" : "html"
      template_path = Rails.root.join("app/views/blog/exports/index.#{extension}.erb")
      template = ERB.new(File.read(template_path), trim_mode: "-")

      File.open(File.join(dir, "#{filename}.#{extension}"), "w") do |file|
        file.write(template.result(binding))
      end
    end

    def export_post(post, dir, filename: nil)
      images_dir = File.join(dir, "images")
      FileUtils.mkdir_p(images_dir)

      stripped_html = Html::StripActionTextAttachments.new.transform(post.content.to_s)
      stripped_html = Html::Sanitize.new.transform(stripped_html)

      extension = markdown? ? "md" : "html"
      template_path = Rails.root.join("app/views/blog/exports/post.#{extension}.erb")

      if markdown?
        @post_content = html_to_markdown(Blog::Export::ImageHandler.new(post, images_dir).process_images(stripped_html))
      else
        @post_content = Blog::Export::ImageHandler.new(post, images_dir).process_images(stripped_html)
      end

      template = ERB.new(File.read(template_path), trim_mode: "-")

      filename ||= post.slug
      File.open(File.join(dir, "#{filename}.#{extension}"), "w") do |file|
        file.write(template.result(binding))
      end
    end

    def html_to_markdown(html)
      ReverseMarkdown.convert(html, github_flavored: true)
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
