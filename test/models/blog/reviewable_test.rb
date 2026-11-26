require "test_helper"

class Blog::ReviewableTest < ActiveSupport::TestCase
  test "a blog created by a subscriber skips review" do
    assert users(:annie).blogs.create!(subdomain: "annieextra").reviewed_at
    assert_nil User.create!(email: "newuser@newuser.com", blogs_attributes: [ { subdomain: "newuser" } ]).blog.reviewed_at
  end

  test "a blog with an empty bio and only drafts has nothing to review" do
    blog = blogs(:unengaged)
    blog.update!(bio: "<p><br></p>")
    blog.posts.create!(title: "Draft", content: "Not yet", status: :draft)

    assert_not blog.reviewable?
  end

  test "a published post gives a blog something to review" do
    blogs(:unengaged).posts.create!(title: "Hello", content: "First post")

    assert blogs(:unengaged).reviewable?
  end

  test "bio text gives a blog something to review" do
    blogs(:unengaged).update!(bio: "<p>Locally informed insights</p>")

    assert blogs(:unengaged).reviewable?
  end

  test "a navigation link gives a blog something to review" do
    blogs(:unengaged).navigation_items.create!(type: "CustomNavigationItem", label: "Shop", url: "https://shop.test")

    assert blogs(:unengaged).reviewable?
  end

  test "a custom footer gives a blog something to review" do
    blogs(:unengaged).update!(custom_footer_html: %(<a href="https://shop.test">Shop</a>))

    assert blogs(:unengaged).reviewable?
  end

  test "search_indexable? waits for review" do
    blog = blogs(:elliot)
    blog.update!(reviewed_at: nil)

    assert_not blog.search_indexable?

    blog.update!(reviewed_at: Time.current)
    assert blog.search_indexable?
  end

  test "search_indexable? skips the wait for a paying user" do
    blog = blogs(:joel)
    blog.update!(reviewed_at: nil)

    assert blog.user.subscribed?
    assert blog.search_indexable?
  end
end
