require "test_helper"
require "mocha/minitest"

class MarketingAutomation::AddContactJobTest < ActiveJob::TestCase
  def setup
    @user = users(:joel)
  end

  test "should add to Pagecord mailing list if consented" do
    @user.update! marketing_consent: true

    assert_difference("EmailSubscriber.count", 1) do
      MarketingAutomation::AddContactJob.perform_now(@user.id)

      # ensure it's not added twice
      MarketingAutomation::AddContactJob.perform_now(@user.id)
    end

  subscriber = EmailSubscriber.find_by(email: @user.email)
  assert_not_nil subscriber
  assert subscriber.confirmed?
  end

  test "should not add to Pagecord mailing list if not consented" do
    assert_no_difference("EmailSubscriber.count") do
      MarketingAutomation::AddContactJob.perform_now(@user.id)
    end
  end
end
