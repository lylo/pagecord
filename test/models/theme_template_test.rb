require "test_helper"

class ThemeTemplateTest < ActiveSupport::TestCase
  setup do
    @template = theme_templates(:minimal_mono)
  end

  test "every template has a stylesheet" do
    ThemeTemplate.find_each { assert it.stylesheet?, "#{it.name} has no #{it.stylesheet}.css" }
  end

  test "stylesheet is the slug for version 1 and carries later versions" do
    assert_equal "themes/minimal-mono", @template.stylesheet
    assert_equal "themes/minimal-mono-2", @template.stylesheet(2)
  end

  test "versions are only this template's numbered stylesheets" do
    assert_equal [ 1 ], @template.stylesheet_versions
    assert_equal [ 1 ], theme_templates(:halcyon).stylesheet_versions
  end

  test "slug comes from the name and can't change once saved" do
    template = ThemeTemplate.new(name: "Minimal Mono")
    template.valid?
    assert_equal "minimal-mono", template.slug

    assert_raises(ActiveRecord::ReadonlyAttributeError) { @template.update(slug: "renamed") }
    assert_equal "minimal-mono", @template.reload.slug
  end

  test "version must have a stylesheet" do
    @template.version = 9

    assert_not @template.valid?
    assert_match(/themes\/minimal-mono-9\.css/, @template.errors[:version].first)
  end

  test "recognises an untouched copy of a template's css" do
    assert ThemeTemplate.copied_css?(@template.css)
    assert ThemeTemplate.copied_css?("#{@template.css.strip}\n\n")
    assert ThemeTemplate.copied_css?(@template.css.gsub("\n", "\r\n"))
    assert_not ThemeTemplate.copied_css?("#{@template.css}\n.mine { color: red; }")
    assert_not ThemeTemplate.copied_css?(nil)
  end

  test "a blog is offered the active templates and the one it uses" do
    @template.update!(active: false)
    blog = blogs(:joel)

    assert_not_includes ThemeTemplate.offered_to(blog), @template

    blog.apply_design(@template)
    assert_includes ThemeTemplate.offered_to(blog), @template
  end

  test "cannot be deleted while a blog uses it" do
    blogs(:joel).apply_design(@template)

    assert_not @template.destroy
    assert ThemeTemplate.exists?(@template.id)
  end
end
