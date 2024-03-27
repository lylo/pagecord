require "test_helper"
require "mocha/minitest"

class PostsMailboxTest < ActionMailbox::TestCase
  test "should receive plain text mail to valid address from valid recipient" do
    user = users(:joel)

    assert_difference -> { user.posts.count }, 1 do
      receive_inbound_email_from_mail \
        to: user.delivery_email,
        from: user.email,
          reply_to: user.email,
        subject: "Hello world!",
        body: "Hello?" do |mail|
          mail.header["Received-SPF"] = "pass"
      end
    end

    assert_equal "Hello world!", user.posts.last.title
    assert_equal "Hello?", user.posts.last.content
  end

  test "should receive valid HTML mail from HEY" do
    user = users(:joel)
    raw_mail = File.read(Rails.root.join('test/fixtures/emails/hey.eml'))

    assert_difference -> { user.posts.count }, 1 do
      receive_inbound_email_from_source raw_mail
    end

    assert_equal "Another test", user.posts.last.title

    mail = Mail.new(raw_mail)
    assert_equal "<div><div><div>This is a test.<br><br>With multiple paragraphs.<br><br>Ok?<br><br><strong>Does it work?</strong></div></div></div>", format_html(user.posts.last.content)
    assert user.posts.last.html?
    assert Time.parse("Thu, 21 Mar 2024 16:57:12 +0000"), user.posts.last.published_at
  end

  test "should receive valid HTML mail from Fastmail" do
    user = users(:joel)
    raw_mail = File.read(Rails.root.join('test/fixtures/emails/fastmail.eml'))
    mail = Mail.read_from_string(raw_mail)

    assert_difference -> { user.posts.count }, 1 do
      receive_inbound_email_from_source raw_mail
    end

    assert_equal "Hello, World 👋", user.posts.last.title

    expected = <<~HTML
    <div><b>It's alive!&nbsp;</b><br></div><div><br></div><div>Say hello to Pagecord&nbsp;( * ^ *) ノシ<b></b><br></div><div><br></div><div>It's a minimalist blogging / writing app driven entirely by email. To publish, simply send an email to your unique Pagecord email address and it will appear on your blog. That's it!<br></div><div><br></div><div>Pagecord is minimal in how it looks, but also in what it does. You can use basic markup like&nbsp;<b>bold</b>,&nbsp;<i>italic</i>, <s>strikethough</s>, <a href=\"https://www.youtube.com/watch?v=dQw4w9WgXcQ\">links</a>&nbsp;and whatnot in your writing. And you can use emojis&nbsp;🥳&nbsp; But you can't add images. I'm <a href=\"https://docs.google.com/forms/d/e/1FAIpQLSc5AOBhsW_geuGSNjoQaN1luzISJRfaBxhW2tXP31qchPSdNQ/viewform\">considering a premium tier</a>&nbsp;which would support this, but since it's free I want to keep everything simple and cheap to operate.<br></div><div><br></div><div>You can use Pagecord like a traditional blogging app, where the email subject is the post title and the body is the content. You can also use it like a micro-blog if you prefer, by sending emails with your thoughts in title and leaving the body blank – this way your page will be a super-minimal stream of consciousness.&nbsp;<br></div><div><br></div><div>It's just a bit a fun really. Give it a go and&nbsp;<a href=\"mailto:hello@pagecord.com\">let me know what you think</a>!<br></div><div><br></div><div>-- Olly<br></div>
    HTML

    mail = Mail.new(raw_mail)
    assert_equal expected.strip, format_html(user.posts.last.content)
    assert user.posts.last.html?
    assert Time.parse("Sat, 23 Mar 2024 12:49:33 +0000"), user.posts.last.published_at
  end

  test "should not receive plain text mail to valid address from valid recipient with mismatched reply-to" do
    user = users(:joel)

    assert_difference -> { user.posts.count }, 0 do
      receive_inbound_email_from_mail \
        to: user.delivery_email,
        from: user.email,
        reply_to: "dodgy@example.com",
        subject: "Hello world!",
        body: "Hello?"
    end
  end

  test "should not receive plain text mail to valid address from valid recipient with failed SPF" do
    user = users(:joel)

    assert_difference -> { user.posts.count }, 0 do
      receive_inbound_email_from_mail \
        to: user.delivery_email,
        from: user.email,
        reply_to: "dodgy@example.com",
        subject: "Hello world!",
        body: "Hello?" do |mail|
          mail.header["Received-SPF"] = "fail"
        end
    end
  end

  test "should not receive mail to valid address from invalid recipient" do
    user = users(:joel)

    assert_difference -> { user.posts.count }, 0 do
      receive_inbound_email_from_mail \
        to: user.delivery_email,
        from: "who@example.com",
        reply_to: user.email,
        subject: "Hello world!",
        body: "Hello?"
    end
  end

  test "mail to invalid address should raise routing error" do
    assert_raises ActionMailbox::Router::RoutingError do
      receive_inbound_email_from_mail \
      to: '"someone" <someone@unknown.com>',
      from: '"else" <else@example.com>',
      subject: "Hello world!",
      body: "Hello?"
    end
  end

  test "should correctly store email with blank subject, non-blank plain text body" do
    user = users(:joel)

    assert_difference -> { user.posts.count }, 1 do
      receive_inbound_email_from_mail \
        to: user.delivery_email,
        from: user.email,
        reply_to: user.email,
        subject: "",
        body: "Hello?"
    end

    assert_nil user.posts.last.title
    assert_equal "Hello?", user.posts.last.content
  end

  test "should correctly store non-blank subject, blank plain text body" do
    user = users(:joel)

    assert_difference -> { user.posts.count }, 1 do
      receive_inbound_email_from_mail \
        to: user.delivery_email,
        from: user.email,
        reply_to: user.email,
        subject: "This is like a tweet",
        body: ""
    end

    assert_nil user.posts.last.title
    assert_equal "<p>This is like a tweet</p>", user.posts.last.content
  end

  test "should correctly store non-blank subject, blank HTML message body" do
    user = users(:joel)

    mail = Mail.new do
      to user.delivery_email
      from user.email
      reply_to user.email
      subject "This is like a tweet"
      text_part do
        body ""
      end
      html_part do
        body "<div><br></div>"
      end
    end

    assert_difference -> { user.posts.count }, 1 do
      receive_inbound_email_from_source mail.to_s
    end

    assert_nil user.posts.last.title
    assert_equal "<p>This is like a tweet</p>", user.posts.last.content
  end

  test "should correctly store blank subject, non-blank HTML message body" do
    user = users(:joel)

    mail = Mail.new do
      to user.delivery_email
      from user.email
      reply_to user.email
      subject ""
      text_part do
        body ""
      end
      html_part do
        body "<!DOCTYPE html><html><head><title></title><style type=\"text/css\">p.MsoNormal,p.MsoNoSpacing{margin:0}</style></head><body><div style=\"font-family:Arial;\">Ok, I caved. Pagecord now tentatively supports images. All you need to do is include a link to an image and it <s>will</s> should be automatically unfurled. Here's hoping...<br></div><div style=\"font-family:Arial;\"><br></div><div style=\"font-family:Arial;\"><a href=\"https://gifdb.com/images/high/snoop-dogg-party-time-qb0t29sqslut7ugb.gif\" rel=\"noopener noreferrer\" target=\"_blank\">https://gifdb.com/images/high/snoop-dogg-party-time-qb0t29sqslut7ugb.gif</a><br></div></body></html>"
      end
    end

    assert_difference -> { user.posts.count }, 1 do
      receive_inbound_email_from_source mail.to_s
    end

    assert_nil user.posts.last.title
    assert_equal "<div>Ok, I caved. Pagecord now tentatively supports images. All you need to do is include a link to an image and it <s>will</s> should be automatically unfurled. Here's hoping...<br></div><div><br></div><div><img src=\"https://gifdb.com/images/high/snoop-dogg-party-time-qb0t29sqslut7ugb.gif\"><br></div>", format_html(user.posts.last.content)
  end

  test "should correctly store blank subject, image in HTML body" do
    FastImage.stubs(:size).returns([800, 600])
    FastImage.stubs(:type).returns(:jpeg)

    user = users(:joel)

    mail = Mail.new do
      to user.delivery_email
      from user.email
      reply_to user.email
      subject ""
      text_part do
        body ""
      end
      html_part do
        body "<div><a href=\"http://example.com/image.jpg\">http://example.com/image.jpg</a></div>"
      end
    end

    assert_difference -> { user.posts.count }, 1 do
      receive_inbound_email_from_source mail.to_s
    end

    assert_nil user.posts.last.title
    assert_equal "<div><img src=\"http://example.com/image.jpg\"></div>", format_html(user.posts.last.content)
  end

  test "should not store blank subject, blank message body" do
    user = users(:joel)

    assert_difference -> { user.posts.count }, 0 do
      receive_inbound_email_from_mail \
        to: user.delivery_email,
        from: user.email,
        reply_to: user.email,
        subject: "",
        body: ""
    end
  end

  private

    def format_html(html)
      html.strip.gsub(/^ +/, '').gsub(/\n/, '')
    end
end
