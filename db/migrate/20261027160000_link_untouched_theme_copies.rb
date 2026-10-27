# Blogs whose custom_css is an untouched copy of a template are linked to that
# template's first stylesheet instead, which holds the same CSS. Only these
# columns are written, so no other callback touches a customer's blog.
class LinkUntouchedThemeCopies < ActiveRecord::Migration[8.2]
  STYLESHEETS = Rails.root.join("app/assets/stylesheets/themes")

  def up
    templates = select_rows("SELECT id, name, slug, custom_css FROM theme_templates").to_h do |id, name, slug, css|
      path = STYLESHEETS.join("#{slug}.css")
      raise "#{name}: themes/#{slug}.css is missing" unless path.exist?
      raise "#{name}: themes/#{slug}.css differs from the database" unless normalize(path.read) == normalize(css)

      [ normalize(css), [ id, name ] ]
    end

    linked = Hash.new(0)

    Blog.where.not(custom_css: [ nil, "" ]).find_each do |blog|
      id, name = templates[normalize(blog.custom_css)]
      next unless id

      blog.update_columns(theme_template_id: id, theme_template_version: 1, custom_css: nil, updated_at: Time.current)
      PurgeCloudflareCacheJob.set(wait: 1.minute).perform_later(blog.id) if Rails.env.production?
      linked[name] += 1
    end

    say "Linked #{linked.values.sum} blogs: #{linked.sort.map { "#{_1} #{_2}" }.join(", ")}"
  end

  def down
    Blog.where.not(theme_template_id: nil).where(custom_css: nil).find_each do |blog|
      css = select_value("SELECT custom_css FROM theme_templates WHERE id = #{blog.theme_template_id.to_i}")
      blog.update_columns(custom_css: css, theme_template_id: nil, theme_template_version: nil, updated_at: Time.current)
    end
  end

  private

    def normalize(css)
      css.to_s.gsub("\r\n", "\n").strip
    end
end
