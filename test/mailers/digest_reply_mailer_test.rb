require "test_helper"

class DigestReplyMailerTest < ActionMailer::TestCase
  test "forward_reply sends email to blog owner with correct subject and body" do
    digest = post_digests(:one)
    blog_owner = digest.blog.user

    # Create a mock original mail
    original_mail = Mail.new do
      from "subscriber@example.com"
      subject "Thanks for the digest!"
      body "I really enjoyed your latest posts about Rails."
      content_type "text/plain"
    end

    email = DigestReplyMailer.with(
      digest: digest,
      original_mail: original_mail
    ).forward_reply

    assert_emails 1 do
      email.deliver_now
    end

    assert_equal [ blog_owner.email ], email.to
    assert_equal "subscriber@example.com <hello@notifications.pagecord.com>", email[:from].value
    assert_equal "subscriber@example.com", email.reply_to.first
    assert_equal "Re: #{digest.subject}", email.subject
    assert_equal "I really enjoyed your latest posts about Rails.", email.body.to_s
    assert_match(/text\/plain/, email.content_type)
  end

  test "forward_reply converts an HTML-only reply to plain text" do
    digest = post_digests(:one)

    original_mail = Mail.new do
      from "subscriber@example.com"
      subject "Thanks!"
      body "<p>Great <strong>content</strong>!</p>"
      content_type "text/html"
    end

    email = DigestReplyMailer.with(
      digest: digest,
      original_mail: original_mail
    ).forward_reply

    assert_match(/text\/plain/, email.content_type)
    assert_equal "Great content!", email.body.to_s
  end

  test "forward_reply prefers the text part of a multipart reply" do
    digest = post_digests(:one)

    original_mail = Mail.new do
      from "subscriber@example.com"
      subject "Thanks!"
      text_part { body "Plain version" }
      html_part { body "<p>HTML <em>version</em></p>" }
    end

    email = DigestReplyMailer.with(
      digest: digest,
      original_mail: original_mail
    ).forward_reply

    assert_match(/text\/plain/, email.content_type)
    assert_equal "Plain version", email.body.to_s
  end

  test "forward_reply falls back to the html part when there is no text part" do
    digest = post_digests(:one)

    original_mail = Mail.new do
      from "subscriber@example.com"
      subject "Thanks!"
      html_part { body "<p>Only <em>HTML</em> here</p>" }
    end

    email = DigestReplyMailer.with(
      digest: digest,
      original_mail: original_mail
    ).forward_reply

    assert_match(/text\/plain/, email.content_type)
    assert_equal "Only HTML here", email.body.to_s
  end

  test "forward_reply drops inline attachments" do
    digest = post_digests(:one)

    original_mail = Mail.new do
      from "subscriber@example.com"
      subject "Thanks!"
      text_part { body "See the logo" }
      add_file filename: "space.jpg", content: File.read(Rails.root.join("test/fixtures/files/space.jpg"))
    end

    email = DigestReplyMailer.with(
      digest: digest,
      original_mail: original_mail
    ).forward_reply

    assert_empty email.attachments
    assert_equal "See the logo", email.body.to_s
  end

  test "forward_reply does not send if no from address" do
    digest = post_digests(:one)

    original_mail = Mail.new do
      from nil
      subject "Thanks!"
      body "Great content!"
    end

    assert_no_emails do
      DigestReplyMailer.with(
        digest: digest,
        original_mail: original_mail
      ).forward_reply.deliver_now
    end
  end

  test "forward_reply uses display name when available" do
    digest = post_digests(:one)
    blog_owner = digest.blog.user

    # Create a mock original mail with display name
    original_mail = Mail.new do
      from "John Doe <subscriber@example.com>"
      subject "Thanks for the digest!"
      body "I really enjoyed your latest posts about Rails."
      content_type "text/plain"
    end

    email = DigestReplyMailer.with(
      digest: digest,
      original_mail: original_mail
    ).forward_reply

    assert_equal [ blog_owner.email ], email.to
    assert_equal "John Doe <hello@notifications.pagecord.com>", email[:from].value
    assert_equal "subscriber@example.com", email.reply_to.first
    assert_equal "Re: #{digest.subject}", email.subject
  end

  test "forward_reply uses correct subject with digest date" do
    digest = post_digests(:one)
    digest.update!(created_at: Date.parse("2025-03-15"))

    original_mail = Mail.new do
      from "subscriber@example.com"
      subject "Original subject"
      body "Content here"
    end

    email = DigestReplyMailer.with(
      digest: digest,
      original_mail: original_mail
    ).forward_reply

    # Should reconstruct the original digest subject with the digest's creation date
    expected_subject = I18n.with_locale(digest.blog.locale) do
      I18n.t(
        "email_subscribers.mailers.weekly_digest.subject",
        blog_name: digest.blog.display_name,
        date: I18n.l(Date.parse("2025-03-15"), format: :post_date)
      )
    end

    assert_equal "Re: #{expected_subject}", email.subject
  end
end
