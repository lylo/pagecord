require "date"
require_relative "log_parser"

# Signals that need acting on the same day: a mailer sending far more than
# usual, one blog's subscriptions surging, a public form under attack.
module LogCodeRed
  MAIL_JOB_RE = /Performing ActionMailer::MailDeliveryJob .*with arguments: "([^"]+)", "([^"]+)"/

  FORMS = {
    "Blogs::EmailSubscribersController" => "Subscribe",
    "Blogs::ContactMessagesController" => "Contact",
    "Blogs::Posts::CommentsController" => "Comment",
    "Blogs::Posts::RepliesController" => "Reply",
    "PasswordResetsController" => "Password reset",
    "SignupsController" => "Signup"
  }.freeze

  # Keep in step with EmailSubscribable::DAILY_UNCONFIRMED_SUBSCRIBER_LIMIT.
  CONFIRMATIONS_PER_BLOG = 5
  SUBSCRIBE_IPS_PER_BLOG = 20
  MAIL_SURGE_FACTOR = 2
  MAIL_SURGE_MINIMUM = 10
  BASELINE_DAYS = 7

  class << self
    # Job lines carry no request header, so LogParser skips them; read them raw.
    def mail_counts(lines)
      lines.each_with_object(Hash.new { |h, k| h[k] = Hash.new(0) }) do |line, counts|
        next unless (match = MAIL_JOB_RE.match(line))

        counts["#{match[1]}##{match[2]}"][line[0, 10]] += 1
      end
    end

    def mail_rows(counts, date)
      day = Date.iso8601(date)
      previous = (1..BASELINE_DAYS).map { |n| (day - n).iso8601 }

      rows = counts.map do |mailer, by_day|
        today = by_day[date]
        baseline = previous.sum { |d| by_day[d] } / BASELINE_DAYS.to_f
        { mailer: mailer, today: today, baseline: baseline.round(1), surge: today >= MAIL_SURGE_MINIMUM && today >= baseline * MAIL_SURGE_FACTOR }
      end

      rows.select { |row| row[:today] > 0 || row[:baseline] > 0 }.sort_by { |row| -row[:today] }
    end

    def form_submissions(entries)
      submissions = {}

      entries.each do |entry|
        case entry.line_type
        when :processing
          controller, action = entry.detail.to_s.split("#")
          next unless FORMS.key?(controller) && action == "create"

          submissions[entry.uuid] = { form: FORMS[controller], host: entry.host, ip: entry.ip, block: nil, confirmation: false, paused: false }
        when :other
          submission = submissions[entry.uuid] or next
          body = entry.detail.to_s

          if (reason = body[/\A(.+?)\. Request blocked/, 1])
            submission[:block] = reason
          elsif body.start_with?("Suspicious email blocked")
            submission[:block] = "Suspicious email"
          elsif body.include?('"EmailSubscriptionConfirmationMailer", "confirm"')
            submission[:confirmation] = true
          elsif body.start_with?("Subscriber confirmations paused")
            submission[:paused] = true
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
        confirmations = group.count { |s| s[:confirmation] }
        ips = group.map { |s| s[:ip] }.uniq.size
        paused = group.count { |s| s[:paused] }
        flagged = paused > 0 || confirmations > CONFIRMATIONS_PER_BLOG || ips >= SUBSCRIBE_IPS_PER_BLOG

        { host: host, attempts: group.size, ips: ips, blocked: group.count { |s| s[:block] }, confirmations: confirmations, paused: paused, flagged: flagged }
      end.sort_by { |row| -row[:attempts] }
    end

    def alerts(mail_rows, subscribe_rows)
      mail = mail_rows.select { |row| row[:surge] }.map do |row|
        "#{row[:mailer]} sent #{row[:today]}, against a #{BASELINE_DAYS}-day average of #{row[:baseline]}"
      end

      subscribes = subscribe_rows.select { |row| row[:flagged] }.map do |row|
        reasons = []
        reasons << "cap paused #{row[:paused]} confirmations" if row[:paused] > 0
        reasons << "#{row[:confirmations]} confirmations sent" if row[:confirmations] > CONFIRMATIONS_PER_BLOG
        reasons << "subscribe attempts from #{row[:ips]} IPs" if row[:ips] >= SUBSCRIBE_IPS_PER_BLOG
        "#{row[:host]}: #{reasons.join(", ")}"
      end

      mail + subscribes
    end
  end
end
