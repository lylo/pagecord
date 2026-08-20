require "test_helper"

class Admin::DeliverabilityPurgesControllerTest < ActionDispatch::IntegrationTest
  include AuthenticatedTest

  setup do
    login_as users(:joel)
  end

  def stub_postmark(suppressions: [], bounces: [])
    Postmark::ApiClient.any_instance.stubs(:dump_suppressions).returns(suppressions)
    Postmark::ApiClient.any_instance.stubs(:bounces).returns(bounces)
  end

  test "should require admin access" do
    login_as users(:vivian)
    post admin_deliverability_purge_url
    assert_redirected_to root_path
  end

  test "create deletes suppressed subscribers but spares an occasional soft bounce" do
    stub_postmark(
      suppressions: [ { email_address: "fred@example.com", suppression_reason: "HardBounce", created_at: 1.day.ago } ],
      bounces: [ { email: "geoff@gmail.com", type: "Transient", bounced_at: 1.day.ago } ]
    )

    assert_difference "EmailSubscriber.count", -1 do
      post admin_deliverability_purge_url
    end

    assert_redirected_to admin_deliverability_issues_path
    assert_equal "Deleted 1 subscription across 1 address.", flash[:notice]
    assert EmailSubscriber.exists?(email: "geoff@gmail.com")
  end

  test "create counts subscriptions and addresses separately" do
    EmailSubscriber.create!(blog: blogs(:vivian), email: "fred@example.com", confirmed_at: 1.day.ago)
    stub_postmark(suppressions: [
      { email_address: "fred@example.com", suppression_reason: "HardBounce", created_at: 1.day.ago },
      { email_address: "geoff@gmail.com", suppression_reason: "HardBounce", created_at: 1.day.ago }
    ])

    assert_difference "EmailSubscriber.count", -3 do
      post admin_deliverability_purge_url
    end

    assert_equal "Deleted 3 subscriptions across 2 addresses.", flash[:notice]
  end

  test "create deletes addresses that have bounced past the threshold" do
    stub_postmark(bounces: Array.new(DeliverabilityReport::BOUNCE_THRESHOLD) { |i|
      { email: "fred@example.com", type: "Transient", bounced_at: 1.day.ago, message_id: "m#{i}" }
    })

    assert_difference "EmailSubscriber.count", -1 do
      post admin_deliverability_purge_url
    end
  end

  test "create reports a postmark failure rather than deleting anything" do
    Postmark::ApiClient.any_instance.stubs(:dump_suppressions).raises(Postmark::TimeoutError)

    assert_no_difference "EmailSubscriber.count" do
      post admin_deliverability_purge_url
    end

    assert_redirected_to admin_deliverability_issues_path
    assert_match(/Couldn't load Postmark data/, flash[:alert])
  end
end
