require "test_helper"
require "mocha/minitest"

class MarketingAutomation::DeleteContactJobTest < ActiveJob::TestCase
  def setup
    @user = users(:joel)
  end

  test "should remove from Pagecord mailing list if subscribed" do
    pagecord = Blog.find_by(name: "pagecord")
    pagecord.email_subscribers.create!(email: @user.email)

    assert_difference("EmailSubscriber.count", -1) do
      MarketingAutomation::DeleteContactJob.perform_now(@user.id)
    end
  end

  test "should not remove from Pagecord mailing list if not subscribed" do
    assert_no_difference("EmailSubscriber.count") do
      MarketingAutomation::DeleteContactJob.perform_now(@user.id)
    end
  end
end
