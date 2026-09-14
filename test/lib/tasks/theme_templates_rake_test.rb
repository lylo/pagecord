require "test_helper"
require "rake"

class ThemeTemplatesRakeTest < ActiveSupport::TestCase
  setup do
    Rails.application.load_tasks unless Rake::Task.task_defined?("theme_templates:sync")
    Rake::Task["theme_templates:sync"].reenable

    @template = theme_templates(:minimal_mono)
    @fixture_css = fixture_css_for(@template.name)
  end

  test "sync updates a template that is behind the fixtures" do
    @template.update_column(:custom_css, @fixture_css.sub("article img { border-radius: 0; }", ""))

    capture_io { Rake::Task["theme_templates:sync"].invoke }

    assert_equal @fixture_css, @template.reload.custom_css
  end

  test "sync reports the CSS it replaces" do
    @template.update_column(:custom_css, "#{@fixture_css}\n.admin-tweak { color: red; }\n")

    out, = capture_io { Rake::Task["theme_templates:sync"].invoke }

    assert_equal @fixture_css, @template.reload.custom_css
    assert_match(/replaced\s+\.admin-tweak \{ color: red; \}/, out)
  end

  test "sync leaves a template that matches the fixtures" do
    assert_no_changes -> { @template.reload.updated_at } do
      out, = capture_io { Rake::Task["theme_templates:sync"].invoke }
      assert_match(/#{@template.name}: unchanged/, out)
    end
  end

  test "sync updates only the named theme" do
    other = theme_templates(:novella)
    @template.update_column(:custom_css, "body { color: red; }")
    other.update_column(:custom_css, "body { color: blue; }")

    capture_io { Rake::Task["theme_templates:sync"].invoke("minimal_mono") }

    assert_equal @fixture_css, @template.reload.custom_css
    assert_equal "body { color: blue; }", other.reload.custom_css
  end

  test "sync aborts on an unknown theme" do
    assert_raises(SystemExit) do
      capture_io { Rake::Task["theme_templates:sync"].invoke("nope") }
    end
  end

  test "sync writes nothing on a dry run" do
    @template.update_column(:custom_css, "body { color: red; }")

    with_env("DRY_RUN" => "true") do
      capture_io { Rake::Task["theme_templates:sync"].invoke }
    end

    assert_equal "body { color: red; }", @template.reload.custom_css
  end

  private
    def fixture_css_for(name)
      YAML.load_file(Rails.root.join("test/fixtures/theme_templates.yml"))
          .each_value.find { |attrs| attrs["name"] == name }["custom_css"]
    end

    def with_env(vars)
      original = ENV.slice(*vars.keys)
      ENV.update(vars)
      yield
    ensure
      vars.each_key { |key| original.key?(key) ? ENV[key] = original[key] : ENV.delete(key) }
    end
end
