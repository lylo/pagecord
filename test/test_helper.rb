ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

Dir[File.join(File.dirname(__FILE__), "./support/**/*.rb")].each { |f| require(f) }

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Ensure consistent locale for all tests
    setup do
      I18n.locale = :en
    end

    # Add more helper methods to be used by all tests here...


    # Removes new lines and whitespace between HTML tags for comparison
    def flattened_html(html)
      html.gsub(/\s+/, " ").strip
    end

    def signed_rendered_at(time = 6.seconds.ago)
      Rails.application.message_verifier(:spam_prevention).generate(time.to_i)
    end
  end
end
