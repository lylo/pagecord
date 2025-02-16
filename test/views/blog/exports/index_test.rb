require "test_helper"

class IndexTest < ActionView::TestCase
  setup do
    @blog = blogs(:joel)

    @old_post = @blog.posts.create!(
      title: "Older Post",
      published_at: 2.years.ago,
      content: "Test content"
    )
  end

  test "should render blog title and header" do
    render_template
    assert_select "title", text: @blog.display_name
    assert_select "h1", text: @blog.display_name
  end

  test "should group posts by year" do
    render_template
    assert_select "h2", "#{Time.current.year}"
    assert_select "h2", "#{2.years.ago.year}"
  end

  test "formats post links correctly" do
    render_template

    assert_select "li" do |elements|
      posts = @blog.posts.order(published_at: :desc)
      assert_equal posts.count, elements.count

      elements.each_with_index do |element, index|
        post = posts[index]
        expected_date = post.published_at.strftime("%d %b")
        assert_match(/#{expected_date}/, element.text)
      end
    end
  end

  test "handles untitled posts" do
    @untitled = @blog.posts.create!(
      content: ActionText::Content.new("just some content"),
      published_at: Time.zone.parse("2025-02-01")
    )

    render_template
    assert_select "a", text: "The Art of Street Photography"
  end

  private

    def render_template
      render template: "blog/exports/index", locals: { blog: @blog }
    end
end
