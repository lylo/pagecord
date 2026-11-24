require "test_helper"

class Admin::DeliverabilityPurgesControllerTest < ActionDispatch::IntegrationTest
  include AuthenticatedTest, SesHelpers

  setup do
    login_as users(:joel)
  end

  test "should require admin access" do
    login_as users(:vivian)
    post admin_deliverability_purge_url
    assert_redirected_to root_path
  end

  test "create deletes subscribers SES suppresses and spares the rest" do
    stub_ses(suppressions: [ ses_suppression("fred@example.com") ])

    assert_difference "EmailSubscriber.count", -1 do
      post admin_deliverability_purge_url
    end

    assert_redirected_to admin_deliverability_issues_path
    assert_equal "Deleted 1 subscription across 1 address.", flash[:notice]
    assert EmailSubscriber.exists?(email: "geoff@gmail.com")
  end

  test "create deletes a subscriber saved with capitals" do
    EmailSubscriber.create!(blog: blogs(:vivian), email: "Mixed.Case@Example.com", confirmed_at: 1.day.ago)
    stub_ses(suppressions: [ ses_suppression("mixed.case@example.com") ])

    assert_difference "EmailSubscriber.count", -1 do
      post admin_deliverability_purge_url
    end
  end

  test "create counts subscriptions and addresses separately" do
    EmailSubscriber.create!(blog: blogs(:vivian), email: "fred@example.com", confirmed_at: 1.day.ago)
    stub_ses(suppressions: [ ses_suppression("fred@example.com"), ses_suppression("geoff@gmail.com") ])

    assert_difference "EmailSubscriber.count", -3 do
      post admin_deliverability_purge_url
    end

    assert_equal "Deleted 3 subscriptions across 2 addresses.", flash[:notice]
  end

  test "create reports an SES failure rather than deleting anything" do
    stub_ses.stubs(:list_suppressed_destinations).raises(Aws::SESV2::Errors::AccessDeniedException.new(nil, "denied"))

    assert_no_difference "EmailSubscriber.count" do
      post admin_deliverability_purge_url
    end

    assert_redirected_to admin_deliverability_issues_path
    assert_match(/Couldn't load SES data/, flash[:alert])
  end
end
