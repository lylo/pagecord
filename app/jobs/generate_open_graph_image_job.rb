class GenerateOpenGraphImageJob < ApplicationJob
  queue_as :default

  def perform(post)
    OpenGraphImage.from_post(post)&.save!
  end
end