require "test_helper"
require "rake"

class ThemeTemplatesRakeTest < ActiveSupport::TestCase
  setup do
    Rails.application.load_tasks unless Rake::Task.task_defined?("theme_templates:usage")
    Rake::Task["theme_templates:usage"].reenable
  end

  test "usage counts the blogs on each stylesheet" do
    blogs(:joel).apply_design(theme_templates(:minimal_mono))

    out, = capture_io { Rake::Task["theme_templates:usage"].invoke }

    assert_match(/themes\/minimal-mono\.css \(current\) 1/, out)
    assert_match(/themes\/novella\.css \(current\) 0/, out)
  end

  test "usage counts discarded blogs and flags a missing stylesheet" do
    blog = blogs(:joel)
    blog.apply_design(theme_templates(:minimal_mono))
    blog.update_columns(theme_template_version: 2, discarded_at: Time.current)

    out, = capture_io { Rake::Task["theme_templates:usage"].invoke }

    assert_match(/themes\/minimal-mono-2\.css MISSING 1/, out)
  end
end
