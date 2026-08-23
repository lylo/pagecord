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

    find("lexxy-editor .lexxy-editor__content").click

    assert_selector "lexxy-editor .lexxy-editor__content[autocapitalize='sentences']", wait: 2
  end

  # Lexical drops any element it has no node for, so before the footnote extension
  # existed simply opening and saving a post silently destroyed its footnotes.
  test "footnotes survive a round trip through the editor" do
    post = @user.blog.posts.create!(title: "Footnotes", content: <<~HTML)
      <p>Some text<sup data-footnote-ref="1" id="fnref-1"><a href="#fn-1">1</a></sup>.</p>
      <ol data-footnotes><li id="fn-1"><p>The note.</p></li></ol>
    HTML

    visit edit_app_post_path(post)

    value = editor_value
    assert_includes value, %(data-footnote-ref="1")
    assert_includes value, %(id="fnref-1")
    assert_includes value, %(href="#fn-1")
    assert_includes value, "data-footnotes"
    assert_includes value, %(id="fn-1")
    assert_includes value, "The note."
  end

  test "deleting a footnote marker removes its note and renumbers the rest" do
    post = @user.blog.posts.create!(title: "Footnotes", content: <<~HTML)
      <p>First para<sup data-footnote-ref="1" id="fnref-1"><a href="#fn-1">1</a></sup></p>
      <p>Second para<sup data-footnote-ref="2" id="fnref-2"><a href="#fn-2">2</a></sup></p>
      <ol data-footnotes><li id="fn-1"><p>First note.</p></li><li id="fn-2"><p>Second note.</p></li></ol>
    HTML

    visit edit_app_post_path(post)
    wait_for_editor

    # Each marker ends its paragraph, so :end lands the caret immediately after one
    # with no counting. Backspace then takes the whole marker, it being a token.
    find("lexxy-editor .lexxy-editor__content p", text: "First para").click
    find("lexxy-editor .lexxy-editor__content").send_keys(:end, :backspace)

    assert_selector "lexxy-editor .lexxy-editor__content sup[data-footnote-ref='1']", count: 1, wait: 2

    value = editor_value
    assert_not_includes value, "First note."
    assert_includes value, "Second note."
    # The survivor takes the vacated number, and its note follows.
    assert_includes value, %(data-footnote-ref="1")
    assert_not_includes value, %(data-footnote-ref="2")
    assert_includes value, %(id="fn-1")
  end

  # Markdown lets several references share one definition, and Redcarpet emits
  # exactly that, so the pairing is many-to-one. A one-to-one pairing renumbered the
  # second marker onto a number with no note, and the next pass deleted it.
  test "a footnote referenced twice keeps both markers" do
    post = @user.blog.posts.create!(title: "Footnotes", content: <<~HTML)
      <p>Once<sup data-footnote-ref="1" id="fnref-1"><a href="#fn-1">1</a></sup> and again<sup data-footnote-ref="1" id="fnref-1"><a href="#fn-1">1</a></sup>.</p>
      <ol data-footnotes><li id="fn-1"><p>The shared note.</p></li></ol>
    HTML

    visit edit_app_post_path(post)
    wait_for_editor

    assert_selector "lexxy-editor .lexxy-editor__content sup[data-footnote-ref='1']", count: 2
    assert_selector "lexxy-editor .lexxy-editor__content ol[data-footnotes] li", count: 1
    assert_includes editor_value, "The shared note."
  end

  test "footnoting a selected word keeps the word" do
    post = @user.blog.posts.create!(title: "Footnotes", content: "<p>Annotate somewhere</p>")

    visit edit_app_post_path(post)
    wait_for_editor

    # Select "somewhere", then footnote it. insertNodes replaces a selection, so the
    # marker has to go after the word rather than instead of it.
    find("lexxy-editor .lexxy-editor__content p").double_click
    find("lexxy-toolbar > button[name=footnote]").click

    assert_selector "lexxy-editor .lexxy-editor__content ol[data-footnotes] li", wait: 2

    value = editor_value
    assert_includes value, "Annotate somewhere"
    assert_includes value, %(data-footnote-ref="1")
  end

  test "inserting a footnote from inside a footnote does nothing" do
    post = @user.blog.posts.create!(title: "Footnotes", content: <<~HTML)
      <p>One<sup data-footnote-ref="1" id="fnref-1"><a href="#fn-1">1</a></sup>.</p>
      <ol data-footnotes><li id="fn-1"><p>First note.</p></li></ol>
    HTML

    visit edit_app_post_path(post)
    wait_for_editor

    find("lexxy-editor .lexxy-editor__content ol[data-footnotes] li").click
    find("lexxy-toolbar > button[name=footnote]").click

    assert_selector "lexxy-editor .lexxy-editor__content ol[data-footnotes] li", count: 1
    assert_not_includes editor_value, %(data-footnote-ref="2")
  end

  test "block formatting inside a footnote leaves the note intact" do
    post = @user.blog.posts.create!(title: "Footnotes", content: <<~HTML)
      <p>One<sup data-footnote-ref="1" id="fnref-1"><a href="#fn-1">1</a></sup>.</p>
      <ol data-footnotes><li id="fn-1"><p>First note.</p></li></ol>
    HTML

    visit edit_app_post_path(post)
    wait_for_editor

    find("lexxy-editor .lexxy-editor__content ol[data-footnotes] li").click
    find("lexxy-toolbar > button[name=quote]").click

    # The command lands on the paragraph inside the note, and the shape transform
    # turns it straight back, so the note keeps its text, number and marker.
    assert_no_selector "lexxy-editor .lexxy-editor__content ol[data-footnotes] blockquote"
    assert_selector "lexxy-editor .lexxy-editor__content ol[data-footnotes] li", count: 1

    # A divider is a decorator rather than an element, so it takes the transform's
    # other branch: removed, not folded into a paragraph. Dispatched as the command
    # the button carries, since the button itself may sit in the overflow menu.
    find("lexxy-editor .lexxy-editor__content ol[data-footnotes] li").click
    evaluate_script(<<~JS)
      (() => {
        const editor = document.querySelector("lexxy-editor").editor
        editor.update(() => editor.dispatchCommand("insertHorizontalDivider"))
      })()
    JS
    assert_no_selector "lexxy-editor .lexxy-editor__content ol[data-footnotes] hr"

    value = editor_value
    assert_includes value, "First note."
    assert_includes value, %(data-footnote-ref="1")
    assert_includes value, %(id="fn-1")
  end

  test "the toolbar inserts a footnote" do
    visit new_app_post_path
    wait_for_editor

    find("lexxy-editor .lexxy-editor__content").click
    find("lexxy-editor .lexxy-editor__content").send_keys("Some text")

    # Direct child of the toolbar, not nested inside the link dropdown: nested,
    # it is misplaced and escapes Lexxy's extension-teardown tagging.
    assert_selector "lexxy-toolbar > button[name=footnote]", count: 1
    find("lexxy-toolbar > button[name=footnote]").click

    assert_selector "lexxy-editor .lexxy-editor__content ol[data-footnotes] li", wait: 2

    find("lexxy-editor .lexxy-editor__content").send_keys("The note")

    value = editor_value
    assert_includes value, %(data-footnote-ref="1")
    assert_includes value, %(id="fn-1")
    assert_includes value, "The note"
  end

  # Lexxy strips [data-lexxy-extension] children before re-running the hook, and it
  # only tags direct children of the toolbar, so a nested button would pile up.
  test "the footnote button is not duplicated when the editor reconnects" do
    visit new_app_post_path
    wait_for_editor
    assert_selector "lexxy-toolbar > button[name=footnote]", count: 1

    visit app_posts_path
    visit new_app_post_path
    wait_for_editor

    assert_selector "lexxy-toolbar > button[name=footnote]", count: 1
  end

  test "the toolbar is ordered by what an author reaches for" do
    visit new_app_post_path
    wait_for_editor

    expected = %w[
      image file bold italic strikethrough underline format highlight link
      unordered-list ordered-list quote callout footnote
      code table divider undo redo
    ]

    assert_equal expected, toolbar_control_names
  end

  test "the bio editor does not offer footnotes" do
    visit app_settings_about_index_path

    assert_selector ".lexxy-minimal lexxy-toolbar", wait: 2
    assert_no_selector ".lexxy-minimal lexxy-toolbar button[name=footnote]", visible: true
  end

  private

    def wait_for_editor
      assert_selector "lexxy-editor", wait: 2
      sleep 1
    end

    def editor_value
      wait_for_editor
      evaluate_script("document.querySelector('lexxy-editor').value")
    end

    # The name of each control the toolbar holds, in order. Whatever did not fit is
    # inside the overflow menu rather than a direct child, and Lexxy fills that menu
    # in document order, so the two lists join back up into the full running order.
    def toolbar_control_names
      evaluate_script(<<~JS)
        (() => {
          const toolbar = document.querySelector("lexxy-toolbar")
          const overflow = toolbar.querySelector(".lexxy-editor__toolbar-overflow")
          const visible = Array.from(toolbar.children).filter((child) => child !== overflow)
          const overflowed = Array.from(overflow.querySelector("[data-dropdown-panel]").children)

          return [ ...visible, ...overflowed ].map((child) =>
            child.querySelector("[name]")?.getAttribute("name") ?? child.getAttribute("name"))
        })()
      JS
    end

    def editor_content_attribute(attribute)
      evaluate_script(<<~JS)
        document.querySelector("lexxy-editor .lexxy-editor__content").getAttribute(#{attribute.to_json})
      JS
    end
end
