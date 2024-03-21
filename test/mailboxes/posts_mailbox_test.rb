require "test_helper"

class PostsMailboxTest < ActionMailbox::TestCase
  test "receive plain text mail to valid address from valid recipient" do
    user = users(:joel)

    assert_difference -> { user.posts.count }, 1 do
      receive_inbound_email_from_mail \
        to: user.delivery_email,
        from: user.email,
        subject: "Hello world!",
        body: "Hello?"
    end

    assert_equal user.posts.last.title, "Hello world!"
    assert_equal user.posts.last.content, "Hello?"
  end

  test "receive valid HTML mail from HEY" do
    user = users(:joel)
    raw_mail = File.read(Rails.root.join('test/fixtures/emails/hey.eml'))

    assert_difference -> { user.posts.count }, 1 do
      receive_inbound_email_from_source raw_mail
    end

    assert_equal "Another test", user.posts.last.title

    mail = Mail.new(raw_mail)
    assert_equal MailParser.new(mail).body, user.posts.last.content
  end

  test "receive mail to valid address from invalid recipient" do
    user = users(:joel)

    assert_difference -> { user.posts.count }, 0 do
      receive_inbound_email_from_mail \
        to: user.delivery_email,
        from: "who@example.com",
        subject: "Hello world!",
        body: "Hello?"
    end
  end

  test "receive mail to invalid address" do
    assert_raises ActionMailbox::Router::RoutingError do
      receive_inbound_email_from_mail \
      to: '"someone" <someone@unknown.com>',
      from: '"else" <else@example.com>',
      subject: "Hello world!",
      body: "Hello?"
    end
  end
end
