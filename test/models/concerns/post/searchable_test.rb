require "test_helper"

class Post::SearchableTest < ActiveSupport::TestCase
  setup do
    @blog = blogs(:joel)
  end

  test "keeps a search vector of the title, the text and the image descriptions" do
    image = %(<action-text-attachment content-type="image/png" url="https://example.com/a.png" caption="Wombat" alt="Numbat"></action-text-attachment>)
    post = @blog.posts.create!(title: "Quokka", content: "<p>Rottnest&nbsp;Island</p>#{image}")

    assert_equal %w[ island numbat quokka rottnest wombat ], lexemes(post)
  end

  test "leaves markup out of the search vector" do
    post = @blog.posts.create!(content: %(<p class="quokka"><a href="https://example.com/quokka">Wombats</a></p>))

    assert_equal %w[ wombats ], lexemes(post)
  end

  test "rebuilds the search vector when the content changes" do
    post = @blog.posts.create!(content: "<p>Quokkas</p>")

    post.update!(content: "<p>Wombats</p>")

    assert_equal %w[ wombats ], lexemes(post)
  end

  private
    def lexemes(post)
      Post.where(id: post.id).pick(Arel.sql("tsvector_to_array(search_vector)"))
    end
end
