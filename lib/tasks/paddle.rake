# Replays Paddle webhook fixtures against a running local server so billing flows
# can be tested end to end without driving the Paddle sandbox by hand.
#
# It exercises everything that happens *after* Paddle: the webhook handlers that
# actually set the plan, price, billing dates and send emails. The outbound side
# (change_plan -> Paddle PATCH) still needs the sandbox, since that call is real.
#
# Usage:
#   bin/rails "paddle:simulate[subscription.created,olly,supporter]"
#   bin/rails "paddle:simulate[transaction.completed.plan_change.supporter,olly]"
#   bin/rails "paddle:scenarios"        # list ready-made billing scenarios
#   bin/rails "paddle:flow[upgrade_to_supporter,olly]"
#
# "user" is a blog subdomain, a user id, or an email. Target a different host with
# PADDLE_SIMULATE_URL (default http://localhost:3000). The dev server must be running.

module PaddleSimulator
  module_function

  # Named flows expand to the sequence of webhooks Paddle sends for a scenario.
  # Each step is [fixture, plan_override_or_nil]. Guard the constant so re-loading
  # the rake file (which happens under the test runner) doesn't warn.
  remove_const(:FLOWS) if defined?(FLOWS)
  FLOWS = {
    "signup_annual" => [ [ "subscription.created", "annual" ] ],
    "signup_monthly" => [ [ "subscription.created.monthly", "monthly" ] ],
    "signup_supporter" => [ [ "subscription.created", "supporter" ] ],
    # Upgrade bills immediately (prorated_immediately), so Paddle carries the plan change on transaction.completed.
    "upgrade_to_supporter" => [ [ "transaction.completed.plan_change.supporter", "supporter" ] ],
    # Downgrade uses do_not_bill, so there's no transaction — the plan change arrives on subscription.updated.
    "downgrade_from_supporter" => [ [ "subscription.updated.plan_change", "annual" ] ],
    "renewal" => [ [ "transaction.completed", nil ] ],
    "cancel" => [ [ "subscription.updated.cancellation", nil ] ],
    "payment_failed" => [ [ "transaction.payment_failed", nil ] ]
  }.freeze

  def fixtures_dir
    Rails.root.join("test", "fixtures", "billing")
  end

  def available_fixtures
    Dir.glob(fixtures_dir.join("*.json")).map { |f| File.basename(f, ".json") }.sort
  end

  def find_user(identifier)
    abort "Provide a user (blog subdomain, id, or email)" if identifier.blank?

    user =
      if identifier.match?(/\A\d+\z/)
        User.find_by(id: identifier)
      elsif identifier.include?("@")
        User.find_by(email: identifier)
      else
        Blog.find_by(subdomain: identifier)&.user
      end

    user || abort("No user found for '#{identifier}'")
  end

  def build_payload(fixture, user, plan)
    path = fixtures_dir.join("#{fixture}.json")
    abort "No fixture '#{fixture}'. Available:\n  #{available_fixtures.join("\n  ")}" unless File.exist?(path)

    data = JSON.parse(File.read(path))
    d = data["data"]
    d["custom_data"] ||= {}
    d["custom_data"]["user_id"] = user.id
    d["custom_data"]["blog_subdomain"] = user.blog.subdomain
    d["custom_data"]["plan"] = plan if plan.present?

    # Keep the resulting subscription active by pushing billing dates into the future.
    d["next_billed_at"] = 1.month.from_now.iso8601 if d.key?("next_billed_at")
    if d["billing_period"].is_a?(Hash) && d["billing_period"].key?("ends_at")
      d["billing_period"]["ends_at"] = 1.month.from_now.iso8601
    end

    data.to_json
  end

  def simulate_url
    "#{ENV.fetch("PADDLE_SIMULATE_URL", "http://localhost:3000")}/billing/paddle_events"
  end

  def post(payload)
    require "httparty"

    secret = Rails.application.config_for(:paddle)[:webhook_secret_key]
    warn "⚠️  No Paddle webhook_secret_key configured for #{Rails.env} — the server will reject the signature." if secret.blank?

    ts = Time.current.to_i.to_s
    signature = OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new("sha256"), secret.to_s, "#{ts}:#{payload}")

    HTTParty.post(simulate_url,
      body: payload,
      headers: {
        "Content-Type" => "application/json",
        "Paddle-Signature" => "ts=#{ts};h1=#{signature}"
      })
  rescue Errno::ECONNREFUSED
    abort "Could not reach #{simulate_url}. Is the dev server running? (bin/dev or bin/rails server)"
  end

  def subscription_summary(user)
    s = user.reload.subscription
    return "no subscription" unless s

    cancelled = s.cancelled_at ? s.cancelled_at.to_date.to_s : "no"
    "plan=#{s.plan} price=$#{s.unit_price.to_i / 100} next_billed=#{s.next_billed_at&.to_date} cancelled=#{cancelled}"
  end

  def run(fixture, user, plan)
    payload = build_payload(fixture, user, plan)
    event = JSON.parse(payload)["event_type"]

    before = subscription_summary(user)
    response = post(payload)
    after = subscription_summary(user)

    puts "  #{event}#{plan ? " (plan=#{plan})" : ""}  → HTTP #{response.code}"
    puts "    before: #{before}"
    puts "    after:  #{after}"
  end
end

namespace :paddle do
  desc "Replay a single Paddle webhook fixture. Usage: paddle:simulate[fixture,user,plan]"
  task :simulate, [ :fixture, :user, :plan ] => :environment do |_t, args|
    abort "Refusing to run in production" if Rails.env.production?

    user = PaddleSimulator.find_user(args[:user])
    puts "user ##{user.id} @#{user.blog.subdomain} via #{PaddleSimulator.simulate_url}"
    puts "(the endpoint always returns HTTP 200; watch the before/after state, not the status)"
    PaddleSimulator.run(args[:fixture], user, args[:plan].presence)
  end

  desc "Replay a named billing scenario (see paddle:scenarios). Usage: paddle:flow[name,user]"
  task :flow, [ :name, :user ] => :environment do |_t, args|
    abort "Refusing to run in production" if Rails.env.production?

    steps = PaddleSimulator::FLOWS[args[:name]]
    abort "Unknown flow '#{args[:name]}'. Run paddle:scenarios to list them." unless steps

    user = PaddleSimulator.find_user(args[:user])
    puts "flow '#{args[:name]}' for user ##{user.id} @#{user.blog.subdomain} via #{PaddleSimulator.simulate_url}"
    steps.each { |fixture, plan| PaddleSimulator.run(fixture, user, plan) }
  end

  desc "List available webhook fixtures and named scenarios"
  task scenarios: :environment do
    puts "Named flows (paddle:flow[name,user]):"
    PaddleSimulator::FLOWS.each_key { |name| puts "  #{name}" }
    puts "\nRaw fixtures (paddle:simulate[fixture,user,plan]):"
    PaddleSimulator.available_fixtures.each { |f| puts "  #{f}" }
  end
end
