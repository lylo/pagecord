class EmbedTagProcessor
  TAG_PATTERN = /\{\{\s*embed\s+([^}]+?)\s*\}\}/i

  def initialize(view:)
    @renderer = MediaEmbed::Renderer.new(view: view)
  end

  def process(content)
    return content unless content&.match?(TAG_PATTERN)

    code_blocks = []
    protected_content = content.gsub(%r{<(pre|code)[^>]*>.*?</\1>}m) do |match|
      code_blocks << match
      "___CODE_BLOCK_#{code_blocks.length - 1}___"
    end

    processed = process_fragment(protected_content)

    code_blocks.each_with_index do |block, i|
      processed = processed.sub("___CODE_BLOCK_#{i}___", block)
    end

    processed
  end

  private

    def process_fragment(content)
      fragment = Nokogiri::HTML::DocumentFragment.parse(content)
      replace_block_tags(fragment)
      replace_inline_tags(fragment)
      fragment.to_html
    end

    def replace_block_tags(fragment)
      fragment.css("p, div").each do |node|
        url = embed_url_from(node)
        next unless url

        if (html = @renderer.render(url))
          node.replace(Nokogiri::HTML::DocumentFragment.parse(html))
        else
          node.content = url
        end
      end
    end

    def replace_inline_tags(fragment)
      fragment.xpath(".//text()[contains(., '{{')]").each do |node|
        node.content = node.text.gsub(TAG_PATTERN) { normalize_url($1) }
      end
    end

    def embed_url_from(node)
      text = node.children.filter_map do |child|
        if child.text?
          child.text
        elsif child.element? && child.name == "a"
          bare_link_url(child)
        end
      end.join

      exact_embed_url(text)
    end

    def exact_embed_url(text)
      match = text.strip.match(/\A#{TAG_PATTERN.source}\z/i)
      url = normalize_url(match[1]) if match
      url if url&.match?(/\Ahttps?:\/\//i)
    end

    def normalize_url(url)
      url.to_s.strip
    end

    def bare_link_url(anchor)
      href = normalize_url(anchor["href"])
      text = normalize_url(anchor.text)
      return if href.blank? || text.blank?
      return href if href == text

      href_uri = URI.parse(href)
      text_uri = URI.parse(text)

      href if uri_origin_path(href_uri) == uri_origin_path(text_uri)
    rescue URI::InvalidURIError
      nil
    end

    def uri_origin_path(uri)
      "#{uri.scheme}://#{uri.host}#{uri.path}"
    end
end
