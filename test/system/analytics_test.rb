require "application_system_test_case"

class AnalyticsTest < ApplicationSystemTestCase
  def setup
    @blog = blogs(:joel)
    @post = posts(:one)
  end

  def teardown
    Capybara.app_host = nil
  end

  test "blog index page tracks analytics via Stimulus" do
    # Use the main domain with subdomain in path (like the actual routing)
    visit "/#{@blog.subdomain}"
    
    # Check that the analytics controller is present in the DOM
    assert_selector '[data-controller="analytics"]', visible: false
    assert_selector '[data-analytics-hit-url-value]', visible: false
    
    # Verify the hit URL is correct
    hit_url = find('[data-controller="analytics"]', visible: false)['data-analytics-hit-url-value']
    assert_includes hit_url, '/hit'
  end

  test "individual post page tracks analytics with post token" do
    # Navigate to the post via subdomain path
    visit "/#{@blog.subdomain}/#{@post.slug}"
    
    # Check that analytics controller has post token  
    assert_selector '[data-controller="analytics"]', visible: false
    assert_selector '[data-analytics-post-token-value]', visible: false
    
    # Verify post token is present
    post_token = find('[data-controller="analytics"]', visible: false)['data-analytics-post-token-value']
    assert_equal @post.token, post_token
  end

  test "analytics tracking element is hidden and doesn't affect layout" do
    visit "/#{@blog.subdomain}"
    
    # Element should exist but not be visible (it's a hidden div)
    analytics_element = find('[data-controller="analytics"]', visible: false)
    assert analytics_element.present?
    
    # Should be a div (minimal DOM footprint)
    assert_equal 'div', analytics_element.tag_name.downcase
  end

  test "analytics works on Turbo navigation" do
    visit "/#{@blog.subdomain}"
    
    # Navigate to a post via Turbo
    click_link @post.display_title
    
    # Should now have post-specific analytics tracking
    assert_selector '[data-controller="analytics"]', visible: false
    assert_selector '[data-analytics-post-token-value]', visible: false
    
    post_token = find('[data-controller="analytics"]', visible: false)['data-analytics-post-token-value']
    assert_equal @post.token, post_token
  end

  # Note: We can't easily test the actual beacon requests in system tests
  # since they're fire-and-forget JavaScript calls, but we can test that
  # the Stimulus controller and data attributes are set up correctly
end