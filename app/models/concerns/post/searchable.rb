module Post::Searchable
  extend ActiveSupport::Concern

  included do
    self.ignored_columns += [ "search_vector" ]

    around_save :keep_search_vector

    # Each word is quoted so to_tsquery reads it as text, and :* matches the start of a word.
    scope :search_by_title_and_content, ->(query) {
      tsquery = query.split.map { "' #{it.gsub(/['?\\:]/, " ")} ':*" }.join(" & ")

      where("(posts.search_vector || to_tsvector('simple', array_to_string(posts.tag_list, ' '))) @@ to_tsquery('simple', ?)", tsquery)
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
