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
          dictionary: "simple",
          prefix: true # partial matching
        }
      }

        def self.search_exact_phrase(query)
      return all if query.blank?

      sanitized_query = "%#{sanitize_sql_like(query)}%"

      joins(:rich_text_content)
        .where(
          "posts.title ILIKE ? OR array_to_string(posts.tag_list, ' ') ILIKE ? OR action_text_rich_texts.body ILIKE ?",
          sanitized_query, sanitized_query, sanitized_query
        )
    end
  end
end
