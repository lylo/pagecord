module Post::Searchable
  extend ActiveSupport::Concern

  SEARCH_VECTOR = <<~SQL.squish
    to_tsvector('simple', coalesce(posts.title, '') || ' ' || array_to_string(posts.tag_list, ' ')) ||
    coalesce((
      SELECT to_tsvector('simple', body) FROM action_text_rich_texts
      WHERE record_type = 'Post' AND record_id = posts.id AND name = 'content'
    ), '')
  SQL

  included do
    include PgSearch::Model

    self.ignored_columns += [ "search_vector" ]

    pg_search_scope :search_by_title_and_content,
      using: {
        tsearch: {
          dictionary: "simple",
          prefix: true,
          tsvector_column: "search_vector"
        }
      }

    after_save { self.class.where(id: id).update_search_vectors }

    def self.search_exact_phrase(query)
      return all if query.blank?

      sanitized_query = "%#{sanitize_sql_like(query)}%"

      joins(:rich_text_content)
        .where(
          "posts.title ILIKE ? OR array_to_string(posts.tag_list, ' ') ILIKE ? OR action_text_rich_texts.body ILIKE ?",
          sanitized_query, sanitized_query, sanitized_query
        )
    end

    def self.update_search_vectors
      update_all("search_vector = #{SEARCH_VECTOR}")
    end
  end
end
