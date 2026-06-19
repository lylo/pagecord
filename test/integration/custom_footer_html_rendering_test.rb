require "test_helper"

class CustomFooterHtmlRenderingTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:joel)
    @blog = @user.blog
  end

  test "renders custom footer above Pagecord branding for premium users" do
    @blog.update!(custom_footer_html: '<a href="/about"><img src="/buttons/made-with-pagecord.gif" alt="Made with Pagecord"></a>')
    post = posts(:one)

    get blog_post_url(subdomain: @blog.subdomain, slug: post.slug)

    assert_response :success
    assert_select "footer.blog-footer", count: 1
    assert_select "footer.blog-footer .custom-footer a[href='/about'] img[src='/buttons/made-with-pagecord.gif']"
    assert response.body.index('class="custom-footer"') < response.body.index('id="brand"')
  end

  test "renders safe inline styles in custom footer" do
    @blog.update!(custom_footer_html: '<a href="https://www.buymeacoffee.com/heyolly" target="_blank"><img src="https://cdn.buymeacoffee.com/buttons/v2/default-green.png" alt="Buy Me a Coffee" style="height: 60px !important;width: 217px !important;" ></a>')
    post = posts(:one)

    get blog_post_url(subdomain: @blog.subdomain, slug: post.slug)

    assert_response :success
    assert_select ".custom-footer a[href='https://www.buymeacoffee.com/heyolly'] img[style='height:60px !important;width:217px !important;']"
  end

  test "does not render custom footer for non-premium users" do
    user = users(:vivian)
    user.blog.update!(custom_footer_html: '<a href="https://example.com">Example</a>')
    post = user.blog.posts.first

    get blog_post_url(subdomain: user.blog.subdomain, slug: post.slug)

    assert_response :success
    assert_select ".custom-footer", count: 0
  end
end
