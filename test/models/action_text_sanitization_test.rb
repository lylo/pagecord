require "test_helper"

class ActionTextSanitizationTest < ActiveSupport::TestCase
  test "allows strikethrough tags" do
    content = ActionText::Content.new("<p><s>strikethrough</s></p>")
    assert_includes content.to_s, "<s>strikethrough</s>"
  end

  test "allows underline tags" do
    content = ActionText::Content.new("<p><u>underline</u></p>")
    assert_includes content.to_s, "<u>underline</u>"
  end

  test "allows mark tags" do
    content = ActionText::Content.new("<p><mark>highlighted</mark></p>")
    assert_includes content.to_s, "<mark>highlighted</mark>"
  end
end
