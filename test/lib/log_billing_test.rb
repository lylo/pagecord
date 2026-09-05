require "minitest/autorun"
require_relative "../../lib/log_billing"

class LogBillingTest < Minitest::Test
  def test_reads_only_billing_lines
    parsed = events(
      "[billing] event=renewal user=1 blog=one plan=annual amount=3900",
      "Completed 200 OK in 12ms",
      "Cancelling subscription for 1"
    )

    assert_equal 1, parsed.size
    assert_equal "renewal", parsed.first[:event]
    assert_equal "one", parsed.first[:blog]
  end

  def test_monthly_is_worth_a_year_of_run_rate
    parsed = events("[billing] event=subscription_started user=1 blog=one plan=monthly amount=400")

    assert_equal 4800, LogBilling.annualised_delta(parsed)
  end

  # A cancellation requested weeks earlier: the day access ends must not book
  # the loss a second time.
  def test_access_ending_does_not_move_the_run_rate
    parsed = events(
      "[billing] event=cancel_effective user=1 blog=one plan=monthly amount=400 booked_earlier=true"
    )

    assert_equal 0, LogBilling.annualised_delta(parsed)
  end

  # The in-app form books the loss, and Paddle's webhook describes the same
  # cancellation a second later.
  def test_a_cancellation_and_its_webhook_are_one_loss
    parsed = events(
      "[billing] event=cancel_requested user=1 blog=one plan=monthly amount=400 source=app",
      "[billing] event=cancel_scheduled user=1 blog=one plan=monthly amount=400 source=paddle booked_earlier=true"
    )

    assert_equal(-4800, LogBilling.annualised_delta(parsed))
  end

  # Two declines at checkout, then a subscription. The declines are not a
  # failing renewal, and the subscription is genuinely new.
  def test_a_decline_at_checkout_books_nothing_and_the_start_that_follows_does
    parsed = events(
      "[billing] event=payment_failed user=1 blog=one existing=false",
      "[billing] event=subscription_started user=1 blog=one plan=annual amount=3900"
    )

    assert_equal 3900, LogBilling.annualised_delta(parsed)
  end

  def test_a_plan_change_books_only_the_difference
    parsed = events(
      "[billing] event=plan_changed user=1 blog=one plan=supporter amount=7500 from=annual from_amount=3900"
    )

    assert_equal 3600, LogBilling.annualised_delta(parsed)
  end

  def test_a_spam_removal_is_not_churn
    parsed = events(
      "[billing] event=account_deleted user=1 blog=one plan=annual amount=3900 source=admin reason=spam"
    )

    assert_equal 0, LogBilling.annualised_delta(parsed)
  end

  # Failed renewals, then Paddle cancelled. Nothing was scheduled first, so
  # this is the first and only word of the loss.
  def test_access_ending_with_nothing_booked_earlier_is_a_loss
    parsed = events("[billing] event=cancel_effective user=1 blog=one plan=monthly amount=400 booked_earlier=false")

    assert_equal(-4800, LogBilling.annualised_delta(parsed))
  end

  def test_deleting_an_account_that_had_already_cancelled_books_nothing
    parsed = events("[billing] event=account_deleted user=1 blog=one plan=annual amount=3900 paid=false source=app")

    assert_equal 0, LogBilling.annualised_delta(parsed)
  end

  def test_a_paying_account_deletion_is_a_loss
    parsed = events(
      "[billing] event=account_deleted user=1 blog=one plan=annual amount=3900 paid=true source=app"
    )

    assert_equal(-3900, LogBilling.annualised_delta(parsed))
  end

  def test_a_free_account_deletion_costs_nothing_but_is_still_reported
    parsed = events("[billing] event=account_deleted user=1 blog=one paid=false source=app")

    assert_equal 1, parsed.size
    assert_equal 0, LogBilling.annualised_delta(parsed)
  end

  private

    def events(*bodies)
      entries = bodies.map do |body|
        LogParser.parse_line(
          "2026-09-04T08:10:36+00:00 INFO [abc123] [host=pagecord.com] [ip=203.0.113.1] [user_agent=Paddle] #{body}"
        )
      end

      LogBilling.events_for(entries)
    end
end
