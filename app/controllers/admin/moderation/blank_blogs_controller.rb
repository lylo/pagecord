class Admin::Moderation::BlankBlogsController < Admin::BaseController
  include Pagy::Method

  def index
    @pagy, blogs = pagy(
      Blog.awaiting_content.order(created_at: :desc)
        .includes(:rich_text_bio, :navigation_items, user: [ :subscription, :screening ]),
      limit: 25
    )
    @reviews = Blog::Review.for(blogs)
  end
end
