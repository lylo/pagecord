require "minitest/autorun"
require_relative "../../lib/log_code_red"

class LogCodeRedTest < Minitest::Test
  DATE = "2026-10-08"

  def test_reads_mailer_recipient_and_day_from_mail_jobs
    jobs = LogCodeRed.mail_jobs([
      mail_job("2026-10-08", "AccountVerificationMailer", "login", "User/7"),
      "2026-10-08T10:00:00+00:00 INFO [ActiveJob] Performing PurgeCloudflareCacheJob"
    ])

    assert_equal [ LogCodeRed::MailJob.new("AccountVerificationMailer#login", "User/7", "2026-10-08") ], jobs
  end

  def test_flags_one_recipient_flooded_with_mail_but_not_a_busy_day
    jobs = (1..30).map { |n| job("AccountVerificationMailer#login", "User/#{n}") } +
      Array.new(10) { job("AccountVerificationMailer#login", "User/99") } << job("AccountVerificationMailer#login", "User/99", "2026-10-07")

    assert_equal [ "AccountVerificationMailer#login sent 10 to User/99" ], LogCodeRed.alerts(LogCodeRed.flooded_recipients(jobs, DATE), [])
  end

  def test_tracks_blocks_and_confirmations_per_submission
    submissions = LogCodeRed.form_submissions([
      *subscribe("a", "blog.example", "1.1.1.1", "Tor exit node. Request blocked."),
      *subscribe("b", "blog.example", "2.2.2.2", confirmation),
      processing("c", "Blogs::PostsController#index")
    ])

    assert_equal 2, submissions.size
    assert_equal "Tor exit node", submissions.first[:block]
    assert submissions.last[:confirmation]
  end

  def test_flags_a_blog_sending_more_confirmations_than_the_cap
    entries = (1..6).flat_map { |n| subscribe("r#{n}", "busy.example", "10.0.0.#{n % 2}", confirmation) }

    row = LogCodeRed.subscribe_rows(LogCodeRed.form_submissions(entries)).first

    assert row[:flagged]
    assert_equal [ "busy.example: 6 confirmations sent" ], LogCodeRed.alerts({}, [ row ])
  end

  def test_flags_a_blog_whose_cap_paused_confirmations
    entries = subscribe("a", "quiet.example", "1.1.1.1", "Subscriber confirmations paused. Too many unconfirmed subscribers today.")

    row = LogCodeRed.subscribe_rows(LogCodeRed.form_submissions(entries)).first

    assert row[:flagged]
    assert_equal [ "quiet.example: cap paused 1 confirmations" ], LogCodeRed.alerts({}, [ row ])
  end

  def test_counts_tor_blocks_per_form
    entries = subscribe("a", "blog.example", "1.1.1.1", "Tor exit node. Request blocked.") +
      subscribe("b", "blog.example", "2.2.2.2", "Honeypot field completed. Request blocked.")

    row = LogCodeRed.form_rows(LogCodeRed.form_submissions(entries)).first

    assert_equal 2, row[:attempts]
    assert_equal 0, row[:accepted]
    assert_equal 1, row[:tor]
  end

  private

    def mail_job(date, mailer, action, recipient)
      %(#{date}T10:00:00+00:00 INFO [ActiveJob] [ActionMailer::MailDeliveryJob] [id] Performing ActionMailer::MailDeliveryJob (Job ID: id) from Sidekiq(default) with arguments: "#{mailer}", "#{action}", "deliver_now", {params: {user: #<GlobalID:0x0 @uri=#<URI::GID gid://pagecord/#{recipient}>>}, args: []})
    end

    def job(mailer, recipient, day = DATE)
      LogCodeRed::MailJob.new(mailer, recipient, day)
    end

    def confirmation
      '[ActiveJob] Enqueued ActionMailer::MailDeliveryJob with arguments: "EmailSubscriptionConfirmationMailer", "confirm", "deliver_now"'
    end

    def subscribe(uuid, host, ip, body)
      [ processing(uuid, "Blogs::EmailSubscribersController#create", host: host, ip: ip), other(uuid, body) ]
    end

    def processing(uuid, detail, host: "blog.example", ip: "1.1.1.1")
      LogParser::Entry.new(uuid: uuid, host: host, ip: ip, line_type: :processing, detail: detail)
    end

    def other(uuid, body)
      LogParser::Entry.new(uuid: uuid, line_type: :other, detail: body)
    end
end
