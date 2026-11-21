module Post::Searchable
  extend ActiveSupport::Concern

  included do
    include PgSearch::Model

    self.ignored_columns += [ "search_vector" ]

    around_save :keep_search_vector

    # Fast pg_search without ranking for scalability
    pg_search_scope :search_by_title_and_content,
      against: [ :title, :tag_list ],
      associated_against: {
        rich_text_content: [ :body ]
      },
      using: {
        tsearch: {
          dictionary: "simple",
          prefix: true
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

  def update_search_vector
    self.class.where(id: id).update_all([ "search_vector = to_tsvector('simple', ?)", search_text ])
  end

  private

    def keep_search_vector
      stale = title_changed? || content.changed?
      yield
      update_search_vector if stale
    end

    def search_text
      images = content.body ? content.body.fragment.find_all("#{ActionText::Attachment.tag_name}, img") : []

      [ title, plain_text_content, *images.flat_map { [ it["caption"], it["alt"] ] } ].join(" ")
    end
end
