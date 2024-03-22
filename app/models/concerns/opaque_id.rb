module OpaqueId
  extend ActiveSupport::Concern

  OFFSET = 10_000_000.freeze

  included do
    def url_title
      title.parameterize.truncate(100)
    end

    def url_id
      (id + OFFSET).to_s(36)
    end
  end

  class_methods do
    def from_url_id(url_id)
      url_id.to_i(36) - OFFSET
    end
  end
end
