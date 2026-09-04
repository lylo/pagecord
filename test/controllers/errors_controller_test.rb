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

  test "should get too_many_requests" do
    get "/429"
    assert_response :too_many_requests
  end

  test "should get internal_error" do
    get "/500"
    assert_response :internal_server_error
    assert_select "h1", text: "Something went wrong"
  end

  test "an exception in a request renders the static error page, not the app layout" do
    Home::SpotlightController.any_instance.stubs(:show).raises(RuntimeError, "boom")

    with_exceptions_app do
      get "/spotlight?tab=recent"
    end

    assert_response :internal_server_error
    assert_select "h1", text: "Something went wrong"
    assert_select "header", count: 0
  end

  test "an exception on a custom domain renders the same static error page" do
    blog = blogs(:annie)
    Blogs::PostsController.any_instance.stubs(:index).raises(RuntimeError, "boom")

    with_exceptions_app do
      get "/", headers: { "Host" => blog.custom_domain }
    end

    assert_response :internal_server_error
    assert_select "h1", text: "Something went wrong"
  end

  private

    # The test environment lets exceptions propagate so failures are loud.
    # Route them through exceptions_app the way production does.
    def with_exceptions_app
      env_config = Rails.application.env_config
      previous = env_config.slice("action_dispatch.show_exceptions", "action_dispatch.show_detailed_exceptions")
      env_config["action_dispatch.show_exceptions"] = :all
      env_config["action_dispatch.show_detailed_exceptions"] = false
      yield
    ensure
      env_config.merge!(previous)
    end
end
