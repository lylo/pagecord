require "test_helper"
require "mocha/minitest"

class BlogSpamDetectorTest < ActiveSupport::TestCase
  setup do
    @original_token = ENV["OPENAI_ACCESS_TOKEN"]
    ENV["OPENAI_ACCESS_TOKEN"] = "test_token"
    @blog = blogs(:joel)
    @detector = BlogSpamDetector.new(@blog)
  end

  teardown do
    ENV["OPENAI_ACCESS_TOKEN"] = @original_token
  end

  test "detect returns spam classification" do
    mock_response = {
      "model" => "gpt-4o-mini",
      "choices" => [
        {
          "message" => {
            "content" => { classification: "spam", reason: "Obvious spam" }.to_json
          }
        }
      ]
    }

    OpenAI::Client.any_instance.stubs(:chat).returns(mock_response)

    @detector.detect
    assert_equal :spam, @detector.result.status
    assert_equal "Obvious spam", @detector.result.reason
  end

  test "detect returns clean classification for not_spam response" do
    mock_response = {
      "model" => "gpt-4o-mini",
      "choices" => [
        {
          "message" => {
            "content" => { classification: "not_spam", reason: "Looks clean" }.to_json
          }
        }
      ]
    }

    OpenAI::Client.any_instance.stubs(:chat).returns(mock_response)

    @detector.detect
    assert_equal :clean, @detector.result.status
    assert_equal "Looks clean", @detector.result.reason
  end

  test "detect returns uncertain classification" do
    mock_response = {
      "model" => "gpt-4o-mini",
      "choices" => [
        {
          "message" => {
            "content" => { classification: "uncertain", reason: "Mixed signals" }.to_json
          }
        }
      ]
    }

    OpenAI::Client.any_instance.stubs(:chat).returns(mock_response)

    @detector.detect
    assert_equal :uncertain, @detector.result.status
    assert_equal "Mixed signals", @detector.result.reason
  end

  test "detect returns error on json error" do
    mock_response = {
      "choices" => [
        {
          "message" => {
            "content" => "Not JSON"
          }
        }
      ]
    }

    OpenAI::Client.any_instance.stubs(:chat).returns(mock_response)

    @detector.detect
    assert_equal :error, @detector.result.status
    assert_equal "Failed to parse AI response", @detector.result.reason
  end

  test "detect returns error on api error" do
    OpenAI::Client.any_instance.stubs(:chat).raises(StandardError.new("API Error"))

    @detector.detect
    assert_equal :error, @detector.result.status
    assert_equal "Detection error", @detector.result.reason
  end

  test "detect returns error when missing access token" do
    ENV["OPENAI_ACCESS_TOKEN"] = nil
    detector = BlogSpamDetector.new(@blog)

    detector.detect
    assert_equal :error, detector.result.status
    assert_equal "Missing OpenAI access token", detector.result.reason
  end

  test "normalizes unknown classification values to uncertain" do
    mock_response = {
      "model" => "gpt-4o-mini",
      "choices" => [
        {
          "message" => {
            "content" => { classification: "invalid_value", reason: "test" }.to_json
          }
        }
      ]
    }

    OpenAI::Client.any_instance.stubs(:chat).returns(mock_response)

    @detector.detect
    assert_equal :uncertain, @detector.result.status
  end

  test "returns blank status for empty blogs" do
    empty_blog = Blog.new(subdomain: "empty", user: users(:joel))
    empty_blog.save(validate: false)

    detector = BlogSpamDetector.new(empty_blog)
    detector.detect

    assert_equal :no_content, detector.result.status
    assert_equal "Empty blog - no content to analyze", detector.result.reason
    assert_nil detector.result.model_version
  end

  test "does not skip blog with bio" do
    blog_with_bio = blogs(:joel)
    blog_with_bio.bio = ActionText::Content.new("Test bio")

    detector = BlogSpamDetector.new(blog_with_bio)

    mock_response = {
      "model" => "gpt-4o-mini",
      "choices" => [ { "message" => { "content" => { classification: "not_spam", reason: "Has bio" }.to_json } } ]
    }
    OpenAI::Client.any_instance.stubs(:chat).returns(mock_response)

    detector.detect
    refute_equal :no_content, detector.result.status
  end

  test "prompt includes post links that plain text strips" do
    @blog.posts.create!(content: '<p>Great deals <a href="https://casino.example/bonus">click here</a></p>')

    assert_includes prompt_for(@blog), "casino.example"
    assert_includes prompt_for(@blog), "click here"
  end

  test "prompt includes bio links" do
    @blog.bio = ActionText::Content.new('<a href="https://cheap-loans.example">my site</a>')

    assert_includes prompt_for(@blog), "cheap-loans.example"
  end

  test "prompt includes navigation links" do
    @blog.navigation_items.create!(type: "CustomNavigationItem", label: "Deals", url: "https://pills.example")

    assert_includes prompt_for(@blog), "pills.example"
  end

  test "prompt tallies repeated hosts across posts" do
    3.times { |i| @blog.posts.create!(content: %(<p>#{i} <a href="https://seo-tools.example">link</a></p>)) }

    assert_includes prompt_for(@blog), "seo-tools.example x3"
  end

  test "prompt ignores links back to pagecord" do
    blog = Blog.new(subdomain: "quiet", user: users(:joel))
    blog.save(validate: false)
    blog.posts.create!(content: '<p><a href="https://someone.example.com/post">A friend</a></p>')

    assert_includes prompt_for(blog), "no outbound links"
  end

  test "prompt does not count an embedded image as an outbound link" do
    blog = Blog.new(subdomain: "quiet", user: users(:joel))
    blog.save(validate: false)
    blog.posts.create!(content: '<p>Look at this</p><figure><img src="https://i.imgur.com/abc.jpg"></figure>')

    assert_includes prompt_for(blog), "no outbound links"
  end

  test "prompt strips attachment sgids from post html" do
    blob = ActiveStorage::Blob.create_and_upload!(
      io: StringIO.new("image"), filename: "photo.jpg", content_type: "image/jpeg"
    )
    @blog.posts.create!(content: %(<action-text-attachment sgid="#{blob.attachable_sgid}"></action-text-attachment>))

    refute_includes prompt_for(@blog), blob.attachable_sgid
  end

  test "prompt samples at most POST_SAMPLE_SIZE posts" do
    (BlogSpamDetector::POST_SAMPLE_SIZE + 2).times do |i|
      @blog.posts.create!(title: "Post number #{i}", content: "content #{i}", published_at: i.minutes.ago)
    end

    prompt = prompt_for(@blog)

    assert_includes prompt, "Post number 0"
    refute_includes prompt, "Post number #{BlogSpamDetector::POST_SAMPLE_SIZE + 1}"
  end

  test "link summary counts links past the excerpt limit" do
    filler = "<p>#{"padding " * 200}</p>"
    @blog.posts.create!(content: %(#{filler}<p><a href="https://casino.example/bonus">deal</a></p>))

    prompt = prompt_for(@blog)

    assert_includes prompt, "casino.example x1"
    refute_includes prompt, "casino.example/bonus"
  end

  test "prompt includes page content and its links" do
    @blog.pages.create!(title: "My Links", content: '<p><a href="https://casino.example/bonus">click here</a></p>')

    prompt = prompt_for(@blog)

    assert_includes prompt, "My Links"
    assert_includes prompt, "casino.example x1"
  end

  test "prompt renders a blog with no posts or links" do
    blog = Blog.new(subdomain: "quiet", user: users(:joel))
    blog.save(validate: false)
    blog.bio = ActionText::Content.new("Just writing.")

    prompt = prompt_for(blog)

    assert_includes prompt, "(no posts)"
    assert_includes prompt, "no outbound links"
  end

  private

    def prompt_for(blog)
      BlogSpamDetector.new(blog).send(:prompt)
    end
end
