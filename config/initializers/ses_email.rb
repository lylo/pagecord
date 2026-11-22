require "ses_email/delivery_method"

ActiveSupport.on_load(:action_mailer) do
  ActionMailer::Base.add_delivery_method(:ses, SesEmail::DeliveryMethod)
end
