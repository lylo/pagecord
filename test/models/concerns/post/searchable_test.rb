require "test_helper"

class Post::SearchableTest < ActiveSupport::TestCase
  setup do
    @blog = blogs(:joel)
  end

  test "finds a post by a word in its title, tags or content" do
    post = @blog.posts.create!(title: "Quokka", content: "<p>A day on Rottnest</p>", tags_string: "marsupials")

    %w[ quokka rottnest marsupials ].each do |word|
      assert_equal [ post ], @blog.posts.search_by_title_and_content(word)
    end
  end

  test "matches the start of a word and requires every term" do
    post = @blog.posts.create!(content: "<p>Quokkas on Rottnest</p>")

    assert_equal [ post ], @blog.posts.search_by_title_and_content("quok rott")
    assert_empty @blog.posts.search_by_title_and_content("quokkas wombat")
  end

  test "finds nothing for punctuation alone" do
    @blog.posts.create!(content: "<p>Quokkas</p>")

    assert_empty @blog.posts.search_by_title_and_content("' : \\ ? & | ! (")
  end

  test "follows an edit to the title" do
    post = @blog.posts.create!(title: "Quokkas", content: "<p>Rottnest</p>")

    post.update!(title: "Wombats")

    assert_equal [ post ], @blog.posts.search_by_title_and_content("wombats")
    assert_empty @blog.posts.search_by_title_and_content("quokkas")
  end

  test "follows an edit to the content" do
    post = @blog.posts.create!(content: "<p>Quokkas</p>")

    post.update!(content: "<p>Wombats</p>")

    assert_equal [ post ], @blog.posts.search_by_title_and_content("wombats")
    assert_empty @blog.posts.search_by_title_and_content("quokkas")
  end

  test "does not match markup" do
    @blog.posts.create!(content: %(<p class="quokka"><a href="https://example.com/quokka">Wombats</a></p>))

    assert_empty @blog.posts.search_by_title_and_content("quokka")
  end
end
