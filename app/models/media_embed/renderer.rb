module MediaEmbed
  class Renderer
    def initialize(view:)
      @providers = Providers.all.map { |provider| provider.new(view: view) }
    end

    def render(url)
      @providers.each do |provider|
        html = provider.render(url)
        return html if html.present?
      end

      nil
    end
  end
end
