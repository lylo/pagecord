require "test_helper"

class Blogs::DestroyJobTest < ActiveJob::TestCase
  test "destroys a discarded blog and its posts" do
    blog = blogs(:joel_notes)
    blog.all_posts.create!(content: "Going away")
    blog.discard!

    assert_difference [ "Blog.with_discarded.count", "Post.with_discarded.count" ], -1 do
      Blogs::DestroyJob.perform_now(blog.id)
    end

    assert_not Blog.with_discarded.exists?(blog.id)
  end

  test "frees the subdomain" do
    user = users(:annie)
    blog = user.blogs.create!(subdomain: "purgeme")
    blog.discard!

    Blogs::DestroyJob.perform_now(blog.id)

    assert Blog.new(user: user, subdomain: "purgeme").valid?
  end

  test "does nothing when the blog is already gone" do
    blog = blogs(:joel_notes)
    blog.discard!
    blog.destroy!

    assert_nothing_raised do
      Blogs::DestroyJob.perform_now(blog.id)
    end
  end

  test "does not destroy a blog that was restored before the job ran" do
    blog = blogs(:joel_notes)
    blog.discard!
    blog.undiscard!

    assert_no_difference -> { Blog.with_discarded.count } do
      Blogs::DestroyJob.perform_now(blog.id)
    end
  end
end
