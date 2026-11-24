require "test_helper"

class Admin::DeliverabilityIssuesControllerTest < ActionDispatch::IntegrationTest
  include AuthenticatedTest, SesHelpers

  setup do
    login_as users(:joel)
    stub_ses
  end

  def stub_postmark(suppressions: [], bounces: [])
    Postmark::ApiClient.any_instance.stubs(:dump_suppressions).returns(suppressions)
    Postmark::ApiClient.any_instance.stubs(:bounces).returns(bounces)
  end

  test "should require admin access" do
    login_as users(:vivian)
    get admin_deliverability_issues_url
    assert_redirected_to root_path
  end

  test "index shows suppressions from postmark" do
    stub_postmark(suppressions: [
      { email_address: "fred@example.com", suppression_reason: "HardBounce", created_at: 1.day.ago }
    ])

    get admin_deliverability_issues_url
    assert_response :success
    assert_select "td", text: /fred@example.com/
    assert_select "span", text: /HardBounce/
    assert_select "td", text: /joel/ # subscriber's blog
  end

  test "index shows addresses SES suppresses and the account's health" do
    stub_postmark
    stub_ses(suppressions: [ ses_suppression("fred@example.com") ], sent: 200, bounces: 1)

    get admin_deliverability_issues_url
    assert_response :success
    assert_select "td", text: /fred@example.com/
    assert_select "td", text: /HardBounce\s+SES/
    assert_select "span", text: /Healthy/
    assert_select "p", text: /200 sent,\s+1 hard bounce \(0.50%/
  end

  test "index degrades gracefully when SES is unreachable" do
    stub_postmark
    stub_ses.stubs(:list_suppressed_destinations).raises(Seahorse::Client::NetworkingError.new(RuntimeError.new("timed out")))

    get admin_deliverability_issues_url
    assert_response :success
    assert_select "div", text: /Couldn't load SES data/
  end

  test "index shows repeated bounces with their type and count" do
    stub_postmark(bounces: Array.new(3) { |i| { email: "fred@example.com", type: "Transient", bounced_at: 1.day.ago, message_id: "m#{i}" } })

    get admin_deliverability_issues_url
    assert_response :success
    assert_select "span", text: /Transient ×3/
  end

  test "index lists an address once when it is both suppressed and bouncing" do
    stub_postmark(
      suppressions: [ { email_address: "fred@example.com", suppression_reason: "HardBounce", created_at: 1.day.ago } ],
      bounces: Array.new(4) { |i| { email: "fred@example.com", type: "Transient", bounced_at: 1.day.ago, message_id: "m#{i}" } }
    )

    get admin_deliverability_issues_url
    assert_response :success
    assert_select "td", text: /fred@example.com/, count: 1
    assert_select "span", text: /Transient/, count: 0
  end

  test "index keeps occasional bounces out of the table Delete All acts on" do
    stub_postmark(bounces: [ { email: "fred@example.com", type: "Transient", bounced_at: 1.day.ago } ])

    get admin_deliverability_issues_url
    assert_response :success
    assert_select "p", text: /Nothing needs deleting/
    assert_select "td", text: /fred@example.com/
    assert_select "div", text: "Watching"
  end

  test "index omits addresses with no matching local subscriber" do
    stub_postmark(suppressions: [
      { email_address: "nobody@example.com", suppression_reason: "HardBounce", created_at: 1.day.ago }
    ])

    get admin_deliverability_issues_url
    assert_response :success
    assert_select "p", text: /No delivery problems found/
  end

  test "index shows error message on invalid API key" do
    Postmark::ApiClient.any_instance.stubs(:dump_suppressions).raises(Postmark::InvalidApiKeyError)

    get admin_deliverability_issues_url
    assert_response :success
    assert_select "div", text: /Postmark API token is missing or invalid/
  end

  test "index degrades gracefully when postmark is unreachable" do
    Postmark::ApiClient.any_instance.stubs(:dump_suppressions).raises(Postmark::TimeoutError)

    get admin_deliverability_issues_url
    assert_response :success
    assert_select "div", text: /Couldn't load Postmark data/
  end

  test "destroy deletes every subscription for the address and counts them" do
    EmailSubscriber.create!(blog: blogs(:vivian), email: "fred@example.com", confirmed_at: 1.day.ago)

    assert_difference "EmailSubscriber.count", -2 do
      delete admin_deliverability_issue_url("fred@example.com")
    end

    assert_redirected_to admin_deliverability_issues_path
    assert_equal "Deleted 2 subscriptions.", flash[:notice]
  end
end
