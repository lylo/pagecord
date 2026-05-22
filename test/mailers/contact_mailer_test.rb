require "test_helper"

class ContactMailerTest < ActionMailer::TestCase
  setup do
    @blog = blogs(:joel)
    @contact_message = Blog::ContactMessage.create!(
      blog: @blog,
      name: "Jane Doe",
      email: "jane@example.com",
      message: "Hello, I love your blog!"
    )
  end

  test "new_message sends email to blog owner" do
    email = ContactMailer.with(contact_message: @contact_message).new_message

    assert_emails 1 do
      email.deliver_now
    end

    assert_equal [ @blog.user.email ], email.to
    assert_equal [ "jane@example.com" ], email.reply_to
    assert_includes email.subject, "Jane Doe"
  end

  test "new_message includes sender details in body" do
    email = ContactMailer.with(contact_message: @contact_message).new_message

    assert_match "Jane Doe", email.html_part.body.to_s
    assert_match "jane@example.com", email.html_part.body.to_s
    assert_match "Hello, I love your blog!", email.html_part.body.to_s

    assert_match "Jane Doe", email.text_part.body.to_s
    assert_match "jane@example.com", email.text_part.body.to_s
    assert_match "Hello, I love your blog!", email.text_part.body.to_s
  end
end
