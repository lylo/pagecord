module Post::Searchable
  extend ActiveSupport::Concern

  included do
    include PgSearch::Model

    pg_search_scope :search_by_title_and_content,
      against: [ :title, :tag_list ],
      associated_against: {
        rich_text_content: [ :body ]
      },
      using: {
        tsearch: {
          prefix: true,
          dictionary: "simple",
          normalization: 2,
          any_word: true
        }
      }
  end
end
