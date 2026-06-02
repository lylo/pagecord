require "test_helper"

class Blogs::EmptyTrashJobTest < ActiveJob::TestCase
  test "destroys blogs discarded more than 30 days ago" do
    old_blog = users(:annie).blogs.create!(subdomain: "oldtrash")
    old_blog.discard!
    old_blog.update_columns(discarded_at: 31.days.ago)

    recent_blog = users(:vivian).blogs.first
    recent_blog.discard!
    recent_blog.update_columns(discarded_at: 29.days.ago)

    assert_difference("Blog.with_discarded.count", -1) do
      Blogs::EmptyTrashJob.perform_now
    end

    assert_not Blog.with_discarded.exists?(old_blog.id)
    assert Blog.with_discarded.exists?(recent_blog.id)
  end

  test "does not destroy non-discarded blogs" do
    blog = blogs(:joel)

    assert_no_difference("Blog.with_discarded.count") do
      Blogs::EmptyTrashJob.perform_now
    end

    assert Blog.with_discarded.exists?(blog.id)
  end

  test "frees discarded blog subdomains after cleanup" do
    user = users(:annie)
    discarded_blog = user.blogs.create!(subdomain: "freedtrash")
    discarded_blog.discard!
    discarded_blog.update_columns(discarded_at: 31.days.ago)

    assert_not Blog.new(user: user, subdomain: "freedtrash").valid?

    Blogs::EmptyTrashJob.perform_now

    replacement_blog = Blog.new(user: user, subdomain: "freedtrash")
    assert replacement_blog.valid?
  end
end
