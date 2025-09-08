require "test_helper"

class Html::StripActionTextAttachmentsTest < ActiveSupport::TestCase
  test "should strip action-text-attachment" do
    html = <<~HTML
      <div>
      Hello, World
      <br>
      <action-text-attachment sgid="123">
        <figure>
          <img src="image.jpg" alt="Sample Image">
        </figure>
      </action-text-attachment>
      </div>
    HTML
    expected_html = <<~HTML
      <div>
      Hello, World
      <br>

        <figure>
          <img src="image.jpg" alt="Sample Image">
        </figure>

      </div>
    HTML
    result = Html::StripActionTextAttachments.new.transform(html)
    assert_equal expected_html, result
  end

  test "should preserve figure and figcaption" do
    html = <<~HTML
      <div>
      <action-text-attachment sgid="456">
        <figure>
          <img src="chart.jpg" alt="Sales Chart">
          <figcaption>Q4 Sales Performance</figcaption>
        </figure>
      </action-text-attachment>
      </div>
    HTML
    expected_html = <<~HTML
      <div>

        <figure>
          <img src="chart.jpg" alt="Sales Chart">
          <figcaption>Q4 Sales Performance</figcaption>
        </figure>

      </div>
    HTML
    result = Html::StripActionTextAttachments.new.transform(html)
    assert_equal expected_html, result
  end
end
