require "test_helper"

class SendContactMessageJobTest < ActiveJob::TestCase
  include ActionMailer::TestHelper

  setup do
    @blog = blogs(:joel)
    @contact_message = Blog::ContactMessage.create!(
      blog: @blog,
      name: "Test User",
      email: "sender@example.com",
      message: "Hello, this is a test message."
    )
  end

  test "sends email and deletes contact message" do
    assert_difference "Blog::ContactMessage.count", -1 do
      assert_emails 1 do
        SendContactMessageJob.perform_now(@contact_message.id)
      end
    end

    assert_nil Blog::ContactMessage.find_by(id: @contact_message.id)
  end

  test "does nothing if contact message not found" do
    @contact_message.destroy

    assert_no_difference "Blog::ContactMessage.count" do
      assert_emails 0 do
        SendContactMessageJob.perform_now(@contact_message.id)
      end
    end
  end
end
