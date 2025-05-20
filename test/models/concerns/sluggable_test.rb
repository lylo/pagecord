require "test_helper"

class SluggableTest < ActiveSupport::TestCase
  setup do
    @blog = blogs(:joel)
  end

  test "should generate a slug before creating a post" do
    post = @blog.posts.create!(title: "A New Post")
    assert_equal post.to_title_param, post.slug
  end

  test "should prevent a duplicate slug for the same blog" do
    @blog.posts.as_json
    post1 = @blog.posts.create!(title: "A New Post")

    assert_raises do
      @blog.posts.create!(title: "A New Post", slug: post1.slug)
    end
  end
end
