require "test_helper"

class Home::SupportersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @annie = users(:annie)
    @annie.subscription.update!(plan: :supporter)
  end

  test "should show supporters page" do
    get supporters_path

    assert_response :success
    assert_select "h1", "Supporters"
  end

  test "lists supporter blogs" do
    get supporters_path

    assert_match blogs(:annie).custom_domain, response.body
  end

  test "excludes non-supporters" do
    get supporters_path

    assert_no_match blogs(:vivian).subdomain, response.body
    assert_no_match blogs(:saul).subdomain, response.body
  end

  test "excludes admins" do
    users(:joel).subscription.update!(plan: :supporter)

    get supporters_path

    assert_no_match ">@#{blogs(:joel).subdomain}<", response.body
  end

  test "excludes cancelled supporters" do
    @annie.subscription.update!(cancelled_at: Time.current)

    get supporters_path

    assert_no_match blogs(:annie).custom_domain, response.body
  end

  test "shows one blog per supporter, preferring the custom domain" do
    second_blog = @annie.blogs.create!(subdomain: "anniesecond", delivery_email: "anniesecond_x1@post.example.com")

    get supporters_path

    assert_match blogs(:annie).custom_domain, response.body
    assert_no_match second_blog.subdomain, response.body
  end
end
