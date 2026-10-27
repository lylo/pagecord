require "test_helper"

class ThemeTemplateTest < ActiveSupport::TestCase
  setup do
    @template = theme_templates(:minimal_mono)
  end

  test "stylesheet is the slug for version 1 and carries later versions" do
    assert_equal "themes/minimal-mono", @template.stylesheet
    assert_equal "themes/minimal-mono-2", @template.stylesheet(2)
  end

  test "slug comes from the name" do
    template = ThemeTemplate.new(name: "Minimal Mono")
    template.valid?

    assert_equal "minimal-mono", template.slug
  end

  test "version must have a stylesheet" do
    @template.version = 9

    assert_not @template.valid?
    assert_match(/themes\/minimal-mono-9\.css/, @template.errors[:version].first)
  end

  test "recognises an untouched copy of a template's css" do
    assert ThemeTemplate.copied_css?(@template.css)
    assert ThemeTemplate.copied_css?("#{@template.css.strip}\n\n")
    assert_not ThemeTemplate.copied_css?("#{@template.css}\n.mine { color: red; }")
    assert_not ThemeTemplate.copied_css?(nil)
  end

  test "cannot be deleted while a blog uses it" do
    blogs(:joel).apply_design(@template)

    assert_not @template.destroy
    assert_equal 1, ThemeTemplate.where(id: @template.id).count
  end
end
