class Post::FrontMatter
  MAPPING = {
    "title" => :title, "slug" => :slug, "published_at" => :published_at, "date" => :published_at,
    "canonical_url" => :canonical_url, "locale" => :locale, "status" => :status,
    "hidden" => :hidden, "tags" => :tags_string
  }.freeze

  def self.parse(yaml)
    front_matter = YAML.safe_load(yaml, permitted_classes: [ Date, Time ]) || {}
    attributes = {}

    MAPPING.each do |fm_key, param_key|
      value = front_matter[fm_key]
      next if value.nil?

      attributes[param_key] = param_key == :tags_string ? Array(value).join(", ") : value.to_s
    end

    attributes
  end
end
