# Blogs whose custom_css is exactly the CSS a template had when they applied
# it are linked to that template, from the CSS still held in theme_templates
class LinkUntouchedThemeCopies < ActiveRecord::Migration[8.2]
  def up
    select_rows("SELECT id, custom_css FROM theme_templates WHERE custom_css IS NOT NULL").each do |id, css|
      Blog.where(custom_css: [ css, css.chomp, "#{css.chomp}\n" ]).find_each do |blog|
        blog.assign_attributes(theme_template_id: id, theme_template_version: 1, custom_css: nil)
        blog.save!(validate: false)
      end
    end
  end

  def down
    Blog.where.not(theme_template_id: nil).where(custom_css: nil).includes(:theme_template).find_each do |blog|
      blog.assign_attributes(custom_css: blog.theme_template.css(blog.theme_template_version), theme_template_id: nil, theme_template_version: nil)
      blog.save!(validate: false)
    end
  end
end
