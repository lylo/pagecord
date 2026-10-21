class Admin::Moderation::BlogsController < Admin::BaseController
  include Pagy::Method, Admin::Moderation::Queue

  def index
    @pagy, blogs = pagy(
      queued_blogs(queue_filter).order(created_at: :desc)
        .includes(:rich_text_bio, :navigation_items, user: [ :subscription, :screening ]),
      limit: 25
    )
    @reviews = Blog::Review.for(blogs)
  end
end
