require "test_helper"

class Html::SanitizeTest < ActiveSupport::TestCase
  test "should sanitize html" do
    html = <<~HTML
      <div><p>hello, world!</p><br><figure class="attachment attachment--preview attachment--JPG"><img src="https://example.com/image.jpeg"></figure><br></div>
    HTML

    transformed_html = Html::Sanitize.new.transform(html)

    expected_html = <<~HTML
      <div>
      <p>hello, world!</p>
      <br><figure><img src=\"https://example.com/image.jpeg\"></figure><br>
      </div>
    HTML
    assert_equal expected_html.strip, transformed_html
  end

  test "should preserve lexxy syntax highlighting with single quotes" do
    html = "<pre data-language='ruby'>puts 'hello'</pre>"

    transformed_html = Html::Sanitize.new.transform(html)
    
    puts "Input HTML: #{html}"
    puts "Output HTML: #{transformed_html}"
    
    assert_includes transformed_html, 'data-language'
    assert_includes transformed_html, 'ruby'
  end
end
