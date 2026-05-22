require "test_helper"

class ApplicationJobTest < ActiveSupport::TestCase
  class SentryContextTestJob < ApplicationJob
    def perform(user_id = nil, blog_id = nil)
      user = user_id ? User.find(user_id) : nil
      blog = blog_id ? Blog.find(blog_id) : nil

      with_sentry_context(user: user, blog: blog) do
        "performed"
      end
    end
  end

  test "yields the block when sentry is not initialized" do
    assert_equal "performed", SentryContextTestJob.perform_now
  end

  test "yields the block with user and blog" do
    user = users(:vivian)
    assert_equal "performed", SentryContextTestJob.perform_now(user.id, user.blog.id)
  end
end
