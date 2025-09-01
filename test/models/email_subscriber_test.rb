require "test_helper"

class EmailSubscriberTest < ActiveSupport::TestCase
  test "should generate a token on create" do
    subscriber = blogs(:joel).email_subscribers.create(email: "new@example.com")
    assert subscriber.token.present?
  end

  test "should be unique for a given blog" do
    blog = blogs(:joel)

    assert_raises(ActiveRecord::RecordInvalid) do
      blog.email_subscribers.create!(email: blog.email_subscribers.first.email)
    end

    assert_difference("EmailSubscriber.count", 1) do
      blogs(:vivian).email_subscribers.create!(email: blog.email_subscribers.first.email)
    end
  end
end
