require "test_helper"

class EmailSubscriberTest < ActiveSupport::TestCase
  test "should be unique for a given blog" do
    blog = blogs(:joel)

    assert_raises(ActiveRecord::RecordNotUnique) do
      blog.email_subscribers.create!(email: blog.email_subscribers.first.email)
    end

    assert_difference("EmailSubscriber.count", 1) do
      blogs(:vivian).email_subscribers.create!(email: blog.email_subscribers.first.email)
    end
  end
end
