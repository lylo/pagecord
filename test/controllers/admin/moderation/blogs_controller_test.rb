require "test_helper"

class Admin::Moderation::BlogsControllerTest < ActionDispatch::IntegrationTest
  include AuthenticatedTest

  setup do
    login_as users(:joel)
    Blog.update_all(reviewed_at: Time.current)
    @blog = blogs(:annie)
    @blog.update!(reviewed_at: nil)
  end

  test "lists blogs that have not been reviewed" do
    get admin_moderation_blogs_path

    assert_response :success
    assert_match "@#{@blog.subdomain}", response.body
  end

  test "leaves out blogs that have been reviewed" do
    get admin_moderation_blogs_path

    assert_no_match "@#{blogs(:vivian).subdomain}", response.body
  end

  test "leaves out blogs whose user has been discarded" do
    @blog.user.discard!

    get admin_moderation_blogs_path

    assert_no_match "@#{@blog.subdomain}", response.body
  end

  test "says in plain words why the owner failed screening" do
    @blog.user.create_screening!(failed_checks: { cleantalk: "FORBIDDEN BL" })

    get admin_moderation_blogs_path

    assert_match "Screening: IP or email on CleanTalk&#39;s blacklist", response.body
  end

  test "links each blog to its admin account page" do
    get admin_moderation_blogs_path

    assert_match admin_user_path(@blog.user), response.body
  end

  test "shows the blog's latest posts inline" do
    get admin_moderation_blogs_path

    assert_select "##{dom_id(@blog)}", text: /#{posts(:four).title}/
  end

  test "the links filter keeps blogs whose posts link elsewhere" do
    blogs(:elliot).update!(reviewed_at: nil)
    posts(:four).update!(content: %(<p><a href="https://shop.test">buy</a></p>))

    get admin_moderation_blogs_path(filter: "links")

    assert_select "##{dom_id(@blog)}"
    assert_select "##{dom_id(blogs(:elliot))}", count: 0
  end

  test "the links filter counts a host that only contains the app's domain as outside" do
    posts(:four).update!(content: %(<p><a href="https://example.com.shop.test">buy</a></p>))
    blogs(:elliot).update!(reviewed_at: nil, bio: %(<p><a href="https://annie.example.com/">mine</a></p>))

    get admin_moderation_blogs_path(filter: "links")

    assert_select "##{dom_id(@blog)}"
    assert_select "##{dom_id(blogs(:elliot))}", count: 0
  end

  test "the screening filter keeps blogs whose owner failed screening" do
    blogs(:elliot).update!(reviewed_at: nil)
    blogs(:elliot).user.create_screening!(failed_checks: { cleantalk: "FORBIDDEN BL" })

    get admin_moderation_blogs_path(filter: "screening")

    assert_select "##{dom_id(blogs(:elliot))}"
    assert_select "##{dom_id(@blog)}", count: 0
  end

  test "the unverified filter keeps blogs whose owner hasn't verified" do
    blogs(:elliot).update!(reviewed_at: nil)

    get admin_moderation_blogs_path(filter: "unverified")

    assert_select "##{dom_id(blogs(:elliot))}"
    assert_select "##{dom_id(@blog)}", count: 0
  end
end
