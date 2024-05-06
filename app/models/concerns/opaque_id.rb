module OpaqueId
  extend ActiveSupport::Concern

  OFFSET = 100_000_000.freeze

  included do
    def url_title
      title&.parameterize&.truncate(100) || ""
    end

    def url_id
      (id + OFFSET).to_s(16)
    end
  end

  class_methods do
    def id_from_url_id(url_id)
      url_id.to_i(16) - OFFSET
    end
  end
end
