require "test_helper"

class MailParserTest < ActiveSupport::TestCase
  # ========================================
  # Tag Extraction Tests
  # ========================================

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

  # ========================================
  # Multipart Email Tests
  # ========================================

  test "should parse multipart/alternative and prefer HTML" do
    mail = Mail.read(fixture_path("multipart_alternative.eml"))
    parser = MailParser.new(mail, process_attachments: false)

    assert_includes parser.body, "<strong>HTML</strong>"
    assert_not_includes parser.body, "plain text content"
  end

  test "should handle Apple Mail edge case with multiple HTML fragments" do
    mail = Mail.read(fixture_path("apple_mail_edge_case.eml"))
    parser = MailParser.new(mail, process_attachments: false)

    assert_includes parser.body, "First paragraph before image"
    assert_includes parser.body, "Second paragraph after image"
  end

  test "should handle multipart/related with inline images" do
    mail = Mail.read(fixture_path("multipart_related_inline_image.eml"))
    parser = MailParser.new(mail)

    assert_includes parser.body, "Check out this image"
    assert parser.has_attachments?, "Should detect inline image as attachment"
  end

  test "should handle plain text with image attachments" do
    mail = Mail.read(fixture_path("plain_text_with_attachments.eml"))
    parser = MailParser.new(mail)

    assert_includes parser.body, "Here is some text content"
    assert parser.has_attachments?, "Should detect attachment"
    assert_equal 1, parser.attachments.size
  end

  test "should embed attachments in content for multipart/mixed emails" do
    mail = Mail.read(fixture_path("plain_text_with_attachments.eml"))
    parser = MailParser.new(mail)

    # Verify the attachment is embedded in the content as ActionText attachment
    assert_includes parser.body, "<action-text-attachment",
      "Attachment should be embedded as action-text-attachment in the content"

    # Verify attachment attributes are present
    assert_includes parser.body, 'content-type="image/jpeg"'
    assert_includes parser.body, 'filename="attachment.jpg"'

    # Verify text content is preserved along with the attachment
    assert_includes parser.body, "Here is some text content"

    # Verify this is treated as having attachments
    assert parser.has_attachments?
    assert_equal 1, parser.attachments.size

    # Verify the attachment blob properties
    attachment = parser.attachments.first
    assert_equal "attachment.jpg", attachment.filename.to_s
    assert_equal "image/jpeg", attachment.content_type
  end

  test "should handle multipart/mixed emails with multiple attachments" do
    mail = Mail.read(fixture_path("multipart_mixed_multiple_attachments.eml"))
    parser = MailParser.new(mail)

    # Should embed both attachments in content
    action_text_attachments = parser.body.scan(/<action-text-attachment/).size
    assert_equal 2, action_text_attachments, "Should embed both attachments in content"

    # Should detect both attachments
    assert_equal 2, parser.attachments.size
    assert parser.has_attachments?

    # Should preserve text content
    assert_includes parser.body, "Text with multiple images below."

    # Verify attachment details
    filenames = parser.attachments.map(&:filename).map(&:to_s).sort
    assert_equal [ "image1.jpg", "image2.png" ], filenames
  end

  # ========================================
  # Edge Cases and Error Handling
  # ========================================

  test "should handle empty email" do
    mail = Mail.read(fixture_path("empty_email.eml"))
    parser = MailParser.new(mail, process_attachments: false)

    assert parser.blank?, "Email with no subject or body should be blank"
    assert parser.subject_blank?
    assert parser.body_blank?
  end

  test "should handle email with empty subject" do
    mail = create_mail(subject: "", body: "Content here")
    parser = MailParser.new(mail, process_attachments: false)

    assert parser.subject_blank?
    assert_not parser.body_blank?
    assert_not parser.blank?
  end

  test "should handle email with empty body" do
    mail = create_mail(subject: "Test", body: "")
    parser = MailParser.new(mail, process_attachments: false)

    assert_not parser.subject_blank?
    assert parser.body_blank?
    assert_not parser.blank?
  end

  test "should handle email with only whitespace in body" do
    mail = create_mail(subject: "Test", body: "   \n\n   ")
    parser = MailParser.new(mail, process_attachments: false)

    assert parser.body_blank?
  end

  # ========================================
  # Attachment Tests
  # ========================================

  test "should return empty array when no attachments" do
    mail = create_mail(subject: "Test", body: "Content")
    parser = MailParser.new(mail, process_attachments: false)

    assert_equal [], parser.attachments
    assert_not parser.has_attachments?
  end

  test "should not process attachments when process_attachments is false" do
    mail = Mail.read(fixture_path("plain_text_with_attachments.eml"))
    parser = MailParser.new(mail, process_attachments: false)

    assert_equal [], parser.attachments
    assert_not parser.has_attachments?
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

    def fixture_path(filename)
      Rails.root.join("test", "fixtures", "emails", filename)
    end
end
