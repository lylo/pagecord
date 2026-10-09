require "minitest/autorun"
require_relative "../../lib/log_code_red"

class LogCodeRedTest < Minitest::Test
  DATE = "2026-10-08"

  def test_counts_mail_jobs_per_mailer_and_day
    counts = LogCodeRed.mail_counts([
      mail_job("2026-10-08", "AccountVerificationMailer", "login"),
      mail_job("2026-10-08", "AccountVerificationMailer", "login"),
      mail_job("2026-10-07", "WelcomeMailer", "welcome_email"),
      "2026-10-08T10:00:00+00:00 INFO [ActiveJob] Performing PurgeCloudflareCacheJob"
    ])

    assert_equal 2, counts["AccountVerificationMailer#login"]["2026-10-08"]
    assert_equal 1, counts["WelcomeMailer#welcome_email"]["2026-10-07"]
    assert_equal 2, counts.size
  end

  def test_a_mailer_at_twice_its_baseline_is_a_surge
    counts = { "AccountVerificationMailer#login" => Hash.new(0).merge("2026-10-08" => 20, "2026-10-07" => 7, "2026-10-06" => 7) }

    row = LogCodeRed.mail_rows(counts, DATE).first

    assert_equal 2.0, row[:baseline]
    assert row[:surge]
  end

  def test_a_small_mailer_is_never_a_surge
    counts = { "AdminMailer#deliverability_digest" => Hash.new(0).merge("2026-10-08" => 3) }

    refute LogCodeRed.mail_rows(counts, DATE).first[:surge]
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
    assert_equal [ "busy.example: 6 confirmations sent" ], LogCodeRed.alerts([], [ row ])
  end

  def test_flags_a_blog_whose_cap_paused_confirmations
    entries = subscribe("a", "quiet.example", "1.1.1.1", "Subscriber confirmations paused. Too many unconfirmed subscribers today.")

    row = LogCodeRed.subscribe_rows(LogCodeRed.form_submissions(entries)).first

    assert row[:flagged]
    assert_equal [ "quiet.example: cap paused 1 confirmations" ], LogCodeRed.alerts([], [ row ])
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

    def mail_job(date, mailer, action)
      %(#{date}T10:00:00+00:00 INFO [ActiveJob] [ActionMailer::MailDeliveryJob] [id] Performing ActionMailer::MailDeliveryJob (Job ID: id) from Sidekiq(default) with arguments: "#{mailer}", "#{action}", "deliver_now")
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
