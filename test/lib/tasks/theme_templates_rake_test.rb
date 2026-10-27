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

    assert_match(/themes\/minimal-mono\.css \(current\): 1/, out)
    assert_match(/themes\/novella\.css \(current\): 0/, out)
  end
end
