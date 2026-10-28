require "date"
require_relative "log_parser"

# Signals that need acting on the same day: one person flooded with mail,
# one blog's subscriptions surging, a public form under attack.
module LogCodeRed
  MAIL_JOB_RE = /Performing ActionMailer::MailDeliveryJob .*with arguments: "([^"]+)", "([^"]+)"/
  MAIL_RECIPIENT_RE = %r{gid://[^/]+/(\w+/\d+)}
  MailJob = Struct.new(:mailer, :recipient, :day)

  FORMS = {
    "Blogs::EmailSubscribersController" => "Subscribe",
    "Blogs::ContactMessagesController" => "Contact",
    "Blogs::Posts::CommentsController" => "Comment",
    "Blogs::Posts::RepliesController" => "Reply",
    "PasswordResetsController" => "Password reset",
    "SignupsController" => "Signup"
  }.freeze

  SUBSCRIBE_IPS_PER_BLOG = 20
  MAIL_PER_RECIPIENT = 10
  BASELINE_DAYS = 7

  class << self
    # Job lines carry no request header, so LogParser skips them; read them raw.
    def mail_jobs(lines)
      lines.filter_map do |line|
        next unless (match = MAIL_JOB_RE.match(line))

        MailJob.new("#{match[1]}##{match[2]}", line[MAIL_RECIPIENT_RE, 1], line[0, 10])
      end
    end

    def mail_rows(jobs, date)
      previous = (1..BASELINE_DAYS).map { |n| (Date.iso8601(date) - n).iso8601 }

      rows = jobs.group_by(&:mailer).map do |mailer, group|
        { mailer: mailer, today: group.count { |job| job.day == date }, baseline: (group.count { |job| previous.include?(job.day) } / BASELINE_DAYS.to_f).round(1) }
      end

      rows.select { |row| row[:today] > 0 || row[:baseline] > 0 }.sort_by { |row| -row[:today] }
    end

    def flooded_recipients(jobs, date)
      jobs.select { |job| job.day == date && job.recipient }.map { |job| [ job.mailer, job.recipient ] }.tally.select { |_, n| n >= MAIL_PER_RECIPIENT }
    end

    def form_submissions(entries)
      submissions = {}

      entries.each do |entry|
        case entry.line_type
        when :processing
          controller, action = entry.detail.to_s.split("#")
          next unless FORMS.key?(controller) && action == "create"

          submissions[entry.uuid] = { form: FORMS[controller], host: entry.host, ip: entry.ip, block: nil, confirmation: false }
        when :other
          submission = submissions[entry.uuid] or next
          body = entry.detail.to_s

          if (reason = body[/\A(.+?)\. Request blocked/, 1])
            submission[:block] = reason
          elsif body.start_with?("Suspicious email blocked")
            submission[:block] = "Suspicious email"
          elsif body.include?('"EmailSubscriptionConfirmationMailer", "confirm"')
            submission[:confirmation] = true
          end
        end
      end

      submissions.values
    end

    def form_rows(submissions)
      submissions.group_by { |s| s[:form] }.map do |form, group|
        blocked = group.select { |s| s[:block] }
        { form: form, attempts: group.size, accepted: group.size - blocked.size, tor: blocked.count { |s| s[:block] == "Tor exit node" }, blocks: blocked.map { |s| s[:block] }.tally }
      end.sort_by { |row| -row[:attempts] }
    end

    def subscribe_rows(submissions)
      subscribes = submissions.select { |s| s[:form] == "Subscribe" }

      subscribes.group_by { |s| s[:host] }.map do |host, group|
        ips = group.map { |s| s[:ip] }.uniq.size

        { host: host, attempts: group.size, ips: ips, blocked: group.count { |s| s[:block] }, confirmations: group.count { |s| s[:confirmation] }, flagged: ips >= SUBSCRIBE_IPS_PER_BLOG }
      end.sort_by { |row| -row[:attempts] }
    end

    def alerts(flooded_recipients, subscribe_rows)
      floods = flooded_recipients.map { |(mailer, recipient), n| "#{mailer} sent #{n} to #{recipient}" }

      subscribes = subscribe_rows.select { |row| row[:flagged] }.map { |row| "#{row[:host]}: subscribe attempts from #{row[:ips]} IPs" }

      floods + subscribes
    end
  end
end
