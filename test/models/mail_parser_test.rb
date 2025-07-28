require "test_helper"

class MailParserTest < ActiveSupport::TestCase
  test "should extract tags from plain text email" do
    mail = create_mail(
      subject: "Test email",
      body: "This is a post about programming.\n\n#ruby #rails #programming",
      content_type: "text/plain"
    )

    parser = MailParser.new(mail)

    assert_equal [ "programming", "rails", "ruby" ], parser.tags
    assert_not_includes parser.body, "#ruby"
    assert_not_includes parser.body, "#rails"
    assert_not_includes parser.body, "#programming"
    assert_includes parser.body, "This is a post about programming."
  end

  test "should extract tags from HTML email" do
    mail = create_mail(
      subject: "Test HTML email",
      body: "<p>This is a post about web development.</p><p>#javascript #html #css</p>",
      content_type: "text/html"
    )

    parser = MailParser.new(mail)

    assert_equal [ "css", "html", "javascript" ], parser.tags
    # Check that tags are removed from content
    content_text = ActionText::RichText.new(body: parser.body).to_plain_text
    assert_not_includes content_text, "#javascript"
    assert_not_includes content_text, "#html"
    assert_not_includes content_text, "#css"
  end

  test "should return empty array when no tags present" do
    mail = create_mail(
      subject: "Test email",
      body: "This is a regular post without any hashtags.",
      content_type: "text/plain"
    )

    parser = MailParser.new(mail)

    assert_equal [], parser.tags
    assert_includes parser.body, "This is a regular post without any hashtags."
  end

  test "should ignore hashtags in the middle of content" do
    mail = create_mail(
      subject: "Test email",
      body: "I was working on #ruby today.\n\nLater I switched to other things.\n\n#programming #coding",
      content_type: "text/plain"
    )

    parser = MailParser.new(mail)

    assert_equal [ "coding", "programming" ], parser.tags
    assert_includes parser.body, "#ruby today"  # This hashtag should remain
  end

  private

  def create_mail(subject:, body:, content_type: "text/plain", from: "test@example.com", to: "recipient@example.com")
    Mail.new do
      from from
      to to
      subject subject
      content_type content_type
      body body
    end
  end
end
