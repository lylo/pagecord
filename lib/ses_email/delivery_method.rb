module SesEmail
  class DeliveryMethod
    attr_accessor :settings

    def self.client
      Aws::SESV2::Client.new(
        region: ENV.fetch("AWS_SES_REGION", "eu-west-2"),
        credentials: Aws::Credentials.new(ENV["AWS_SES_ACCESS_KEY_ID"], ENV["AWS_SES_SECRET_ACCESS_KEY"])
      )
    end

    def initialize(settings)
      @settings = settings
    end

    def deliver!(mail)
      self.class.client.send_email(
        destination: { to_addresses: mail.smtp_envelope_to },
        content: { raw: { data: mail.to_s } }
      )
    end
  end
end
