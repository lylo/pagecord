class Micropub::PostParams
  ATTRIBUTE_MAP = {
    "name" => :title,
    "mp-slug" => :slug,
    "published" => :published_at,
    "post-status" => :status
  }.freeze

  def initialize(params)
    @params = params || {}
  end

  def to_h
    attrs = ATTRIBUTE_MAP.each_with_object({}) do |(key, attr), h|
      value = property(key)
      h[attr] = value if value.present?
    end

    tags = properties_for("category")
    content = content_html
    attrs[:tag_list] = tags if tags.any?
    attrs[:content] = content if content.present?
    attrs
  end

  private

    # Micropub accepts flat form posts ({ content: "..." }) and mf2 JSON
    # ({ properties: { content: ["..."] } }). Prefer properties when present.
    def properties
      @properties ||= @params[:properties].presence || @params
    end

    def property(key)
      value = properties[key]
      value.is_a?(Array) ? value.first : value
    end

    def properties_for(key)
      value = properties[key]
      return [] if value.nil?

      value.is_a?(Array) ? value : [ value ]
    end

    def content_html
      [ body_html, *photo_html ].compact_blank.join("\n")
    end

    def body_html
      case value = property("content")
      when nil then nil
      when ActionController::Parameters, Hash then content_from_hash(value)
      else Post::Markdown.render(value.to_s).last
      end
    end

    def content_from_hash(value)
      html = value[:html] || value["html"]
      return html.to_s.presence if html.present?

      text = value[:value] || value["value"]
      Post::Markdown.render(text.to_s).last if text.present?
    end

    def photo_html
      properties_for("photo").filter_map do |photo|
        url, alt = photo_url_and_alt(photo)
        next if url.blank?

        %(<img src="#{ERB::Util.html_escape(url)}" alt="#{ERB::Util.html_escape(alt)}">)
      end
    end

    def photo_url_and_alt(photo)
      if photo.is_a?(ActionController::Parameters) || photo.is_a?(Hash)
        [ (photo[:value] || photo["value"]).to_s, (photo[:alt] || photo["alt"]).to_s ]
      else
        [ photo.to_s, "" ]
      end
    end
end
