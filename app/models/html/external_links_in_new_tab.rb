module Html
  class ExternalLinksInNewTab < Transformation
    def initialize(blog)
      @blog = blog
    end

    def transform(html)
      doc = Nokogiri::HTML::DocumentFragment.parse(html)

      doc.css("a[href]").each do |link|
        next unless external?(link["href"])

        link["target"] = "_blank"
        link["rel"] = [ *link["rel"].to_s.split, "noopener" ].uniq.join(" ")
      end

      doc.to_html
    end

    private

      def external?(href)
        uri = URI.parse(href.start_with?("//") ? "https:#{href}" : href)
        return false unless uri.is_a?(URI::HTTP) && uri.host.present?

        !blog_hosts.include?(uri.host.downcase)
      rescue URI::InvalidURIError
        false
      end

      def blog_hosts
        @blog_hosts ||= begin
          hosts = [ "#{@blog.subdomain}.#{Rails.application.config.x.domain}" ]
          hosts += custom_domain_hosts(@blog.custom_domain) if @blog.custom_domain.present?
          hosts.map(&:downcase)
        end
      end

      def custom_domain_hosts(custom_domain)
        apex = custom_domain.delete_prefix("www.")
        [ apex, "www.#{apex}" ]
      end
  end
end
