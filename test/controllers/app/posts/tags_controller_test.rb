require "test_helper"

class App::Posts::TagsControllerTest < ActionDispatch::IntegrationTest
  include AuthenticatedTest

  setup do
    @user = users(:joel)
    login_as @user
    @blog = blogs(:joel)
  end

  test "should list tags with post counts" do
    get app_posts_tags_path

    assert_response :success
    assert_match "photography", response.body
    assert_match "3 posts", response.body
    assert_match "1 post", response.body
  end

  test "should show blank slate when nothing is tagged" do
    @blog.posts.update_all(tag_list: [])

    get app_posts_tags_path

    assert_response :success
    assert_match "You haven't tagged any posts yet", response.body
  end

  test "should rename tag across every post that uses it" do
    patch app_posts_tag_path("photography"), params: { new_name: "Photos" }

    assert_redirected_to app_posts_tags_path
    assert_equal [ "photos" ], posts(:one).reload.tag_list
    assert_equal [ "photos", "technology" ], posts(:photography_and_tech).reload.tag_list
  end

  test "should merge tags when renaming onto an existing tag" do
    patch app_posts_tag_path("photography"), params: { new_name: "technology" }

    assert_redirected_to app_posts_tags_path
    assert_equal [ "technology" ], posts(:one).reload.tag_list
    assert_equal [ "technology" ], posts(:photography_and_tech).reload.tag_list
  end

  test "should say nothing when the name is unchanged" do
    patch app_posts_tag_path("photography"), params: { new_name: "photography" }

    assert_redirected_to app_posts_tags_path
    assert_empty flash
  end

  test "should reject an invalid tag name" do
    patch app_posts_tag_path("photography"), params: { new_name: "not a tag!" }

    assert_redirected_to app_posts_tags_path
    assert_equal "Tags can only contain letters, numbers, and hyphens.", flash[:alert]
    assert_equal [ "photography" ], posts(:one).reload.tag_list
  end

  test "should remove tag from every post that uses it" do
    delete app_posts_tag_path("photography")

    assert_redirected_to app_posts_tags_path
    assert_empty posts(:one).reload.tag_list
    assert_equal [ "technology" ], posts(:photography_and_tech).reload.tag_list
  end

  test "should touch the blog so cached pages re-render" do
    @blog.update_column(:updated_at, 1.day.ago)

    assert_changes -> { @blog.reload.updated_at } do
      delete app_posts_tag_path("photography")
    end
  end

  test "should leave post timestamps alone" do
    assert_no_changes -> { posts(:one).reload.updated_at } do
      patch app_posts_tag_path("photography"), params: { new_name: "photos" }
    end
  end

  test "should not touch another blog's posts" do
    elliot_post = blogs(:elliot).posts.create!(title: "Other post", content: "Content", tag_list: [ "photography" ])

    delete app_posts_tag_path("photography")

    assert_equal [ "photography" ], elliot_post.reload.tag_list
  end

  test "should 404 for a tag the blog doesn't use" do
    delete app_posts_tag_path("nonexistent")

    assert_response :not_found
  end
end
