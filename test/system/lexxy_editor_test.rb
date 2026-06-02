require "application_system_test_case"

class LexxyEditorTest < ApplicationSystemTestCase
  setup do
    I18n.locale = :en
    @user = users(:vivian)

    access_request = @user.access_requests.create!
    visit verify_access_request_path(token: access_request.token_digest)
  end

  test "editor content uses sentence capitalisation" do
    visit new_app_post_path

    assert_selector "lexxy-editor .lexxy-editor__content", wait: 2

    assert_equal "sentences", editor_content_attribute("autocapitalize")
    assert_equal "on", editor_content_attribute("autocorrect")
    assert_equal "true", editor_content_attribute("spellcheck")
  end

  private

    def editor_content_attribute(attribute)
      evaluate_script(<<~JS)
        document.querySelector("lexxy-editor .lexxy-editor__content").getAttribute(#{attribute.to_json})
      JS
    end
end
