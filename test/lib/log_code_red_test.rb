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

  def test_reads_mail_sent_directly_by_jobs
    jobs = LogCodeRed.mail_jobs([
      blog_mail_job("SendContactMessageJob", "job-1", "blog.example"),
      blog_mail_job("SendPostReplyJob", "job-2", "other.example"),
      blog_mail_job("SendContactMessageJob", "job-3", "blog.example"),
      "2026-10-08T10:00:01+00:00 INFO [ActiveJob] [SendContactMessageJob] [job-3] [SendContactMessageJob] Spam detected, destroying contact message 3",
      "2026-10-08T14:00:00+00:00 INFO [ActiveJob] [SendCancellationEmailJob] [job-4] Performing SendCancellationEmailJob (Job ID: job-4) from Sidekiq(default) enqueued at 2026-10-08T10:00:00Z with arguments: 7, {subscriber: true}"
    ])

    assert_equal [
      job("CancellationMailer#subscriber_cancellation", "User/7"),
      job("ContactMailer#new_message", "blog.example"),
      job("ReplyMailer#new_reply", "other.example")
    ], jobs
  end

  def test_flags_a_blog_flooded_with_contact_messages
    jobs = LogCodeRed.mail_jobs((1..10).map { |n| blog_mail_job("SendContactMessageJob", "job-#{n}", "blog.example") })

    assert_equal [ "ContactMailer#new_message sent 10 to blog.example" ], LogCodeRed.alerts(LogCodeRed.flooded_recipients(jobs, DATE), [])
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

  def test_flags_a_blog_subscribed_to_from_many_ips_but_not_from_one
    entries = (1..20).flat_map { |n| subscribe("r#{n}", "busy.example", "10.0.0.#{n}", confirmation) } +
      (1..20).flat_map { |n| subscribe("o#{n}", "owner.example", "10.0.1.1", confirmation) }

    rows = LogCodeRed.subscribe_rows(LogCodeRed.form_submissions(entries))

    assert_equal [ "busy.example: 20 subscription confirmations to attempts from 20 IPs" ], LogCodeRed.alerts({}, rows)
  end

  def test_does_not_flag_a_blog_whose_subscribe_attempts_were_all_blocked
    entries = (1..20).flat_map { |n| subscribe("b#{n}", "busy.example", "10.0.0.#{n}", "Form nonce missing. Request blocked.") }

    rows = LogCodeRed.subscribe_rows(LogCodeRed.form_submissions(entries))

    assert rows.first[:flagged]
    assert_empty LogCodeRed.alerts({}, rows)
  end

  def test_counts_tor_blocks_per_form
    entries = subscribe("a", "blog.example", "1.1.1.1", "Tor exit node. Request blocked.") +
      subscribe("b", "blog.example", "2.2.2.2", "Honeypot field completed. Request blocked.")

    row = LogCodeRed.form_rows(LogCodeRed.form_submissions(entries)).first

    assert_equal 2, row[:attempts]
    assert_equal 0, row[:accepted]
    assert_equal 1, row[:tor]
  end

  def test_counts_only_successful_unblocked_submissions_as_accepted
    entries = [
      processing("a", "SignupsController#create"), completed("a", 302),
      processing("b", "SignupsController#create"), other("b", "Signup refused: banned timezone"), completed("b", 422),
      processing("c", "SignupsController#create"), other("c", "Can't verify CSRF token authenticity."), completed("c", 422)
    ]

    row = LogCodeRed.form_rows(LogCodeRed.form_submissions(entries)).first

    assert_equal 3, row[:attempts]
    assert_equal 1, row[:accepted]
  end

  private

    def mail_job(date, mailer, action, recipient)
      %(#{date}T10:00:00+00:00 INFO [ActiveJob] [ActionMailer::MailDeliveryJob] [id] Performing ActionMailer::MailDeliveryJob (Job ID: id) from Sidekiq(default) with arguments: "#{mailer}", "#{action}", "deliver_now", {params: {user: #<GlobalID:0x0 @uri=#<URI::GID gid://pagecord/#{recipient}>>}, args: []})
    end

    def blog_mail_job(job_class, job_id, host)
      "#{DATE}T10:00:00+00:00 INFO [request-id] [host=#{host}] [ip=1.1.1.1] [ActiveJob] Enqueued #{job_class} (Job ID: #{job_id}) to Sidekiq(default) with arguments: 1, \"1.1.1.1\""
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

    def completed(uuid, status)
      LogParser::Entry.new(uuid: uuid, line_type: :completed, status: status)
    end

    def other(uuid, body)
      LogParser::Entry.new(uuid: uuid, line_type: :other, detail: body)
    end
end
