class PostDigest::DeliveryJob < ApplicationJob
  queue_as :newsletters

  retry_on Postmark::UnexpectedHttpResponseError, wait: :polynomially_longer, attempts: 5
  retry_on Postmark::TimeoutError, wait: :polynomially_longer, attempts: 5
  retry_on Net::OpenTimeout, Net::ReadTimeout, wait: :polynomially_longer, attempts: 5

  def perform(post_digest_id)
    digest = PostDigest.find(post_digest_id)
    PostDigest::PostmarkDelivery.new(digest).deliver_all
  end
end
