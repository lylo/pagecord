require "test_helper"

class ErrorsControllerTest < ActionDispatch::IntegrationTest
  test "should get not_found" do
    get "/404"
    assert_response :not_found
  end

  test "should get not_found with invalid format" do
    get "/404.xml"
    assert_response :not_found
  end

  test "should get unacceptable" do
    get "/422"
    assert_response :unprocessable_entity
  end

  test "should get internal_error" do
    get "/500"
    assert_response :internal_server_error
  end
end