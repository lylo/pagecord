require "test_helper"
require "rake"

class AccountsRakeTest < ActiveSupport::TestCase
  setup do
    Rails.application.load_tasks unless Rake::Task.task_defined?("accounts:purge_unverified")
    Rake::Task["accounts:purge_unverified"].reenable
  end

  test "purge_unverified deletes old unverified accounts and their blogs" do
    user_id, blog_id = users(:elliot).id, blogs(:elliot).id

    Rake::Task["accounts:purge_unverified"].invoke

    assert_not User.exists?(user_id)
    assert_not Blog.with_discarded.exists?(blog_id)
    assert User.exists?(users(:joel).id)
  end
end
