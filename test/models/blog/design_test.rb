require "test_helper"

class Blog::DesignTest < ActiveSupport::TestCase
  setup do
    @blog = blogs(:joel)
    @template = theme_templates(:minimal_mono)
  end

  test "applying a design links the template and its settings" do
    assert @blog.apply_design(@template)

    assert_equal @template, @blog.theme_template
    assert_equal 1, @blog.theme_template_version
    assert_equal "mono", @blog.font
    assert_equal "themes/minimal-mono", @blog.design_stylesheet
  end

  test "applying a design keeps the blog's own css" do
    @blog.update!(custom_css: ".mine { color: red; }")

    @blog.apply_design(@template)

    assert_equal ".mine { color: red; }", @blog.custom_css
  end

  test "applying a design clears an untouched copy of any template's css" do
    @blog.update!(custom_css: theme_templates(:novella).css)

    @blog.apply_design(@template)

    assert_nil @blog.custom_css
  end

  test "a blog without a design has no stylesheet" do
    assert_nil @blog.design_stylesheet
  end
end
