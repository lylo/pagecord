require "test_helper"
require "mocha/minitest"

class Billing::PaddleControllerTest < ActionDispatch::IntegrationTest
  include AuthenticatedTest

  setup do
    @user = users(:joel)
    login_as @user
  end

  test "should return the transaction id for updating the payment method" do
    mock_api = mock
    mock_api.expects(:get_update_payment_method_transaction)
      .with(@user.subscription.paddle_subscription_id)
      .returns({ "data" => { "id" => "txn_01hvrk1481njzb874tn7wyrksv" } })
    PaddleApi.stubs(:new).returns(mock_api)

    post billing_paddle_create_update_payment_method_transaction_path

    assert_response :success
    assert_equal "txn_01hvrk1481njzb874tn7wyrksv", response.parsed_body["transaction_id"]
  end

  # Paddle refuses this once it has cancelled the subscription, which used to 500.
  test "should not error when Paddle returns no transaction" do
    mock_api = mock
    mock_api.expects(:get_update_payment_method_transaction)
      .returns({ "error" => { "code" => "subscription_update_when_canceled" } })
    PaddleApi.stubs(:new).returns(mock_api)

    post billing_paddle_create_update_payment_method_transaction_path

    assert_response :unprocessable_content
  end

  test "should not call Paddle without a subscription" do
    @user.subscription.destroy!
    PaddleApi.expects(:new).never

    post billing_paddle_create_update_payment_method_transaction_path

    assert_response :not_found
  end
end
