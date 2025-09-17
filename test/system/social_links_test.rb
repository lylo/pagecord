require "application_system_test_case"

class SocialLinksTest < ApplicationSystemTestCase
  include RoutingHelper

  setup do
    @user = users(:vivian)
    @blog = @user.blog

    access_request = @user.access_requests.create!

    visit verify_access_request_url(token: access_request.token_digest)

    assert_current_path app_posts_path
  end

  test "preserves URL when changing platform selections" do
    visit app_settings_appearance_index_path

    # First, add a new social link and set it to GitHub
    click_on "Add Link"

    # Find the newly added social link fields
    new_platform_select = all("select[name*='[platform]']").last
    new_url_field = all("input[name*='[url]']").last

    # Set it to GitHub with a URL
    select "GitHub", from: new_platform_select[:id]
    sleep 0.1  # Allow JavaScript to process platform change
    github_url = "https://github.com/example"
    fill_in new_url_field[:id], with: github_url

    # Now change to Bluesky and verify URL is cleared
    select "YouTube", from: new_platform_select[:id]
    sleep 0.1  # Allow JavaScript to process platform change
    assert_equal "", new_url_field.value

    # Add a YouTube URL
    youtube_url = "https://youtube.com/channels/joel"
    fill_in new_url_field[:id], with: youtube_url

    # Change to RSS and verify it's set to RSS feed
    select "RSS", from: new_platform_select[:id]
    sleep 0.1  # Allow JavaScript to process platform change
    assert_match "/feed.xml", new_url_field.value

    # Change back to GitHub and verify original GitHub URL is restored
    select "GitHub", from: new_platform_select[:id]
    sleep 0.1  # Allow JavaScript to process platform change
    assert_equal github_url, new_url_field.value

    # Change back to YouTube and verify the YouTube URL is restored
    select "YouTube", from: new_platform_select[:id]
    sleep 0.1  # Allow JavaScript to process platform change
    assert_equal youtube_url, new_url_field.value

    # Submit the form
    click_on "Update"
    sleep 1  # Allow form submission to complete

    # Verify we're redirected to the main settings page with flash message
    assert_current_path app_settings_path

    # Wait for flash message to become visible (starts hidden, shown via JavaScript)
    assert page.has_selector?("[data-controller='fade']:not(.hidden)", wait: 3)
    assert page.has_content?("Appearance settings updated", wait: 1)

    # Verify the YouTube link was saved
    visit app_settings_appearance_index_path

    saved_platform = all("select[name*='[platform]']").find do |select|
      select.find("option[selected='selected'][value='YouTube']")
    rescue Capybara::ElementNotFound
      false
    end

    assert_not_nil saved_platform, "Could not find select with YouTube option selected"
    saved_url_id = saved_platform[:id].gsub("_platform", "_url")
    saved_url = find_field(saved_url_id)
    assert_equal youtube_url, saved_url.value
  end

  test "can add and remove social links" do
    visit app_settings_appearance_index_path

    # Count initial social links
    initial_count = all("select[name*='[platform]']").count

    click_on "Add Link"

    # Verify a new social link form was added
    assert_equal initial_count + 1, all("select[name*='[platform]']").count

    # Set it to Instagram with a URL
    new_platform_select = all("select[name*='[platform]']").last
    new_url_field = all("input[name*='[url]']").last

    select "Instagram", from: new_platform_select[:id]
    sleep 0.1  # Allow JavaScript to process platform change
    instagram_url = "https://instagram.com/example"
    fill_in new_url_field[:id], with: instagram_url

    click_on "Update"
    sleep 1  # Allow form submission to complete

    # Verify the link was saved - check on the main settings page after redirect
    assert_current_path app_settings_path

    # Wait for flash message to become visible (starts hidden, shown via JavaScript)
    assert page.has_selector?("[data-controller='fade']:not(.hidden)", wait: 3)
    assert page.has_content?("Appearance settings updated", wait: 1)
    visit app_settings_appearance_index_path

    # Now remove the link we just added
    all("a[data-action='click->social-links#removeLink']").last.click

    click_on "Update"
    sleep 1  # Allow form submission to complete

    assert_current_path app_settings_path

    # Wait for flash message to become visible (starts hidden, shown via JavaScript)
    assert page.has_selector?("[data-controller='fade']:not(.hidden)", wait: 3)
    assert page.has_content?("Appearance settings updated", wait: 1)
    visit app_settings_appearance_index_path

    visible_selects = all("select[name*='[platform]']").select(&:visible?)
    assert_equal initial_count, visible_selects.count
  end
end
