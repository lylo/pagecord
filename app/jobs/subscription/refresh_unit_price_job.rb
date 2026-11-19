class Subscription::RefreshUnitPriceJob < ApplicationJob
  queue_as :default

  discard_on ActiveJob::DeserializationError
  retry_on PaddleApi::Error, wait: :polynomially_longer, attempts: 5

  def perform(subscription)
    subscription.refresh_unit_price
  end
end
