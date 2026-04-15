require "application_system_test_case"

class AutosaveTest < ApplicationSystemTestCase
  setup do
    I18n.locale = :en
    @user = users(:vivian)
    @other_blog = users(:joel).blog

    access_request = @user.access_requests.create!
    visit verify_access_request_url(token: access_request.token_digest)

    assert_current_path app_posts_path
  end

  test "new post restores autosaved draft" do
    visit new_app_post_path

    store_draft(rendered_autosave_key, {
      title: "Recovered draft",
      content: "<p>Recovered body</p>"
    })

    visit app_posts_path
    visit new_app_post_path

    wait_for_editor
    assert_equal "Recovered draft", find_field("post[title]").value
    assert_includes editor_value, "Recovered body"
  end

  test "new post ignores autosaved draft from another blog" do
    visit new_app_post_path

    store_draft(new_post_draft_key(@other_blog), {
      title: "Recovered draft",
      content: "<p>Recovered body</p>"
    })

    visit app_posts_path
    visit new_app_post_path

    wait_for_editor
    assert_equal "", find_field("post[title]").value
    refute_includes editor_value, "Recovered body"
  end

  test "existing post restores autosaved draft for the same saved version" do
    post = @user.blog.posts.create!(title: "Saved title", content: "<p>Saved body</p>")

    store_draft("draft-post-#{post.id}", {
      title: "Recovered title",
      content: "<p>Recovered body</p>",
      base: {
        title: post.title,
        content: post.content.body.to_html
      }
    })

    visit edit_app_post_path(post)

    wait_for_editor
    assert_equal "Recovered title", find_field("post[title]").value
    assert_includes editor_value, "Recovered body"
  end

  test "existing post ignores stale autosaved draft from a different saved version" do
    post = @user.blog.posts.create!(title: "Saved title", content: "<p>Saved body</p>")

    store_draft("draft-post-#{post.id}", {
      title: "Recovered title",
      content: "<p>Recovered body</p>",
      base: {
        title: "Older title",
        content: "<p>Older body</p>"
      }
    })

    visit edit_app_post_path(post)

    wait_for_editor
    assert_equal "Saved title", find_field("post[title]").value
    assert_includes editor_value, "Saved body"
    assert_nil draft_for("draft-post-#{post.id}")
  end

  private

    def rendered_autosave_key
      find("[data-autosave-key-value]", visible: false)["data-autosave-key-value"]
    end

    def new_post_draft_key(blog = @user.blog)
      "draft-post-new-#{blog.id}"
    end

    def store_draft(key, value)
      execute_script("localStorage.setItem(#{key.to_json}, JSON.stringify(#{value.to_json}))")
    end

    def draft_for(key)
      evaluate_script("localStorage.getItem(#{key.to_json})")
    end

    def wait_for_editor
      assert_selector "lexxy-editor", wait: 2
      sleep 1
    end

    def editor_value
      wait_for_editor
      evaluate_script("document.querySelector('lexxy-editor').value")
    end
end
