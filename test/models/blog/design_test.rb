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

  test "a preview drops an untouched copy without saving" do
    @blog.update!(custom_css: theme_templates(:novella).css)

    @blog.assign_design(@template)

    assert_nil @blog.custom_css
    assert_equal theme_templates(:novella).css, @blog.reload.custom_css
  end

  test "a design that doesn't set colours keeps the owner's custom colours" do
    @blog.update!(theme: "custom", custom_theme_bg_light: "#123456")

    @blog.apply_design(@template)

    assert_equal "base", @blog.theme
    assert_equal "#123456", @blog.custom_theme_bg_light
  end

  test "switching designs leaves nothing of the previous design's colours" do
    @blog.apply_design(theme_templates(:cardashian))
    assert_equal "#f9f8f6", @blog.custom_theme_bg_light

    @blog.apply_design(@template)

    assert_equal "base", @blog.theme
    assert_nil @blog.custom_theme_bg_light
  end

  test "applying classic unlinks the template and resets the settings" do
    @blog.apply_design(@template)
    @blog.update!(custom_css: ".mine { color: red; }")

    @blog.apply_design(nil)

    assert_nil @blog.theme_template
    assert_nil @blog.theme_template_version
    assert_equal "sans", @blog.font
    assert_equal ".mine { color: red; }", @blog.custom_css
  end

  test "detaching a design copies its css above the blog's own and goes back to classic" do
    @blog.apply_design(@template)
    @blog.update!(custom_css: ".mine { color: red; }")

    assert @blog.detach_design

    assert_nil @blog.theme_template
    assert_equal "#{@template.css.strip}\n\n.mine { color: red; }", @blog.custom_css
  end

  test "detaching a design keeps every @import ahead of the rules" do
    @blog.apply_design(theme_templates(:archibald))
    @blog.update!(custom_css: "@import url('https://fonts.bunny.net/css?family=inter');\n.mine { color: red; }")

    @blog.detach_design

    imports, rules = @blog.custom_css.split("\n\n", 2)
    assert_equal 2, imports.scan("@import").size
    assert_includes imports, "fonts.bunny.net"
    assert_includes imports, "fonts.googleapis.com"
    assert_not_includes rules, "@import"
    assert @blog.custom_css.end_with?(".mine { color: red; }")
  end

  test "a blog without a design has no stylesheet" do
    assert_nil @blog.design_stylesheet
  end

  test "a missing stylesheet falls back to the classic design and is reported" do
    @blog.apply_design(@template)
    @blog.update_column(:theme_template_version, 9)

    Rails.error.expects(:report).once
    assert_nil @blog.reload.design_stylesheet
  end
end
