require "test_helper"

class Blog::ReviewTest < ActiveSupport::TestCase
  setup do
    @blog = blogs(:annie)
  end

  test "shows the latest three published posts and pages, newest first" do
    blog = blogs(:joel)
    expected = Post.kept.published.where(blog: blog).order(published_at: :desc).limit(3).to_a

    review = Blog::Review.for([ blog ]).first

    assert_equal expected, review.latest_posts
    assert_equal Post.kept.published.where(blog: blog).count, review.published_count
  end

  test "counts the outbound hosts a blog links to, leaving out the app's own domain" do
    posts(:four).update!(content: <<~HTML)
      <p><a href="https://www.shop.test/a">one</a> <a href="https://shop.test/b">two</a> <a href="https://annie.example.com">mine</a></p>
    HTML
    @blog.update!(bio: %(<p><a href="https://bio.test/">me</a></p>))
    @blog.navigation_items.create!(type: "CustomNavigationItem", label: "Shop", url: "https://shop.test/c")

    review = Blog::Review.for([ @blog.reload ]).first

    assert_equal({ "shop.test" => 3, "bio.test" => 1 }, review.link_hosts)
    assert_equal({ "shop.test" => 2 }, review.hosts_for(posts(:four)))
  end

  test "counts other signups in the same timezone within the burst window" do
    user = @blog.user
    user.update_columns(timezone: "Kathmandu", created_at: 3.days.ago)
    users(:saul).update_columns(timezone: user.timezone, created_at: user.created_at + 5.minutes)
    users(:elliot).update_columns(timezone: user.timezone, created_at: user.created_at - 10.minutes)
    users(:vivian).update_columns(timezone: user.timezone, created_at: user.created_at + 1.hour)

    review = Blog::Review.for([ @blog ]).first

    assert_equal 2, review.burst_count
    assert review.burst?
  end
end
