class Admin::SuppressionsController < AdminController
  def index
    begin
      suppressions = postmark_client.dump_suppressions("broadcast")
    rescue Postmark::InvalidApiKeyError
      @error = "Postmark API token is missing or invalid. Set POSTMARK_API_TOKEN in your environment."
      suppressions = []
    end

    suppressed_emails = suppressions.map { |s| s[:email_address].downcase }
    subscribers = EmailSubscriber.includes(:blog).where(email: suppressed_emails)
    subscribers_by_email = subscribers.group_by { |s| s.email.downcase }

    @suppressions = suppressions.filter_map do |s|
      email = s[:email_address].downcase
      subs = subscribers_by_email[email]
      next unless subs&.any?
      {
        email: s[:email_address],
        reason: s[:suppression_reason],
        suppressed_at: s[:created_at],
        subscribers: subs
      }
    end.sort_by { |s| s[:suppressed_at] }.reverse

    @affected_subscriber_ids = subscribers.pluck(:id)
  end

  def destroy
    EmailSubscriber.where(email: params[:email]).destroy_all
    redirect_to admin_suppressions_path, notice: "Subscriber deleted."
  end

  def destroy_all
    suppressed_emails = postmark_client.dump_suppressions("broadcast").map { |s| s[:email_address].downcase }
    count = EmailSubscriber.where(email: suppressed_emails).destroy_all.size
    redirect_to admin_suppressions_path,
                notice: "Deleted #{count} suppressed #{"subscriber".pluralize(count)}."
  end

  private

    def postmark_client
      Postmark::ApiClient.new(
        Rails.application.config.action_mailer.postmark_settings&.dig(:api_token) ||
        ENV["POSTMARK_API_TOKEN"]
      )
    end
end
