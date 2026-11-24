require "test_helper"

class Admin::DeliverabilityIssuesControllerTest < ActionDispatch::IntegrationTest
  include AuthenticatedTest, SesHelpers

  setup do
    login_as users(:joel)
    stub_ses
  end

  test "should require admin access" do
    login_as users(:vivian)
    get admin_deliverability_issues_url
    assert_redirected_to root_path
  end

  test "index shows addresses SES suppresses and the account's health" do
    stub_ses(suppressions: [ ses_suppression("fred@example.com") ], sent: 200, bounces: 1)

    get admin_deliverability_issues_url
    assert_response :success
    assert_select "td", text: /fred@example.com/
    assert_select "span", text: /Hard bounce/
    assert_select "td", text: /joel/
    assert_select "span", text: /Healthy/
    assert_select "p", text: /200 sent,\s+1 hard bounce \(0.50%/
  end

  test "index degrades gracefully when SES is unreachable" do
    stub_ses.stubs(:list_suppressed_destinations).raises(Seahorse::Client::NetworkingError.new(RuntimeError.new("timed out")))

    get admin_deliverability_issues_url
    assert_response :success
    assert_select "div", text: /Couldn't load SES data/
  end

  test "index still lists addresses when SES health can't be loaded" do
    stub_ses(suppressions: [ ses_suppression("fred@example.com") ])
      .stubs(:get_account).raises(Seahorse::Client::NetworkingError.new(RuntimeError.new("timed out")))

    get admin_deliverability_issues_url
    assert_response :success
    assert_select "td", text: /fred@example.com/
    assert_select "div", text: /Couldn't load SES data/
  end

  test "index omits addresses with no matching local subscriber" do
    stub_ses(suppressions: [ ses_suppression("nobody@example.com") ])

    get admin_deliverability_issues_url
    assert_response :success
    assert_select "p", text: /No delivery problems found/
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
