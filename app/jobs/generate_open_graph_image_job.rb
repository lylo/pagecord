class GenerateOpenGraphImageJob < ApplicationJob
  queue_as :default

  def perform(post_id)
    if post = Post.find(post_id)
      OpenGraphImage.from_post(post)&.save!
    end
  end
end
