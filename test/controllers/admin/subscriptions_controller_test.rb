require "test_helper"
require "mocha/minitest"

class Admin::SubscriptionsControllerTest < ActionDispatch::IntegrationTest
  include AuthenticatedTest

  setup do
    login_as users(:joel)
  end

  test "should extend subscription and update paddle" do
    user = users(:annie)
    new_date = 6.months.from_now.to_date.to_s

    mock_response = stub(success?: true, body: { data: {} }.to_json)
    mock_api = mock
    mock_api.expects(:patch).returns(mock_response)
    PaddleApi.stubs(:new).returns(mock_api)

    patch admin_user_subscription_url(user), params: { next_billed_at: new_date }

    assert_redirected_to admin_user_path(user)
    assert_equal Time.zone.parse(new_date), user.subscription.reload.next_billed_at
    assert_match "Subscription extended to", flash[:notice]
  end
end
