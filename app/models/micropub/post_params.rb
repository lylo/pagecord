class Micropub::PostParams
  ATTRIBUTE_MAP = {
    "name"        => :title,
    "content"     => :content,
    "mp-slug"     => :slug,
    "published"   => :published_at,
    "post-status" => :status
  }.freeze

  def initialize(params)
    @params = params
  end

  def to_h
    attrs = ATTRIBUTE_MAP.each_with_object({}) do |(key, attr), h|
      next if key == "content"
      value = first(key)
      h[attr] = value if value.present?
    end
    attrs[:tag_list] = categories if categories.any?
    attrs[:content]  = content_html if content_html.present?
    attrs
  end

  private

    # Micropub accepts both flat form posts ({content: "..."}) and mf2 JSON
    # ({properties: {content: ["..."]}}). Treat them uniformly by reading
    # from `properties` when present, otherwise from params directly.
    def properties
      @properties ||= @params[:properties].presence || @params
    end

    def first(key)
      value = properties[key]
      value.is_a?(Array) ? value.first : value
    end

    def all(key)
      value = properties[key]
      return [] if value.nil?
      value.is_a?(Array) ? value : [ value ]
    end

    def categories
      @categories ||= all("category")
    end

    def content_html
      @content_html ||= [ body_html, *photo_html ].compact_blank.join("\n")
    end

    def body_html
      case value = first("content")
      when nil then nil
      when ActionController::Parameters, Hash then (value[:html] || value["html"]).to_s.presence
      else Post::Markdown.render(value.to_s).last
      end
    end

    def photo_html
      all("photo").filter_map do |photo|
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
