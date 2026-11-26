class Admin::Moderation::BlogsController < Admin::BaseController
  include Pagy::Method

  FILTERS = %w[ all links screening ].freeze

  helper_method :queue_filter, :queue_counts

  def index
    @pagy, blogs = pagy(
      queued_blogs(queue_filter).order(created_at: :desc)
        .includes(:rich_text_bio, :navigation_items, user: [ :subscription, :screening ]),
      limit: 25
    )
    @reviews = Blog::Review.for(blogs)
  end

  private
    def queue_filter
      params[:filter].presence_in(FILTERS) || "all"
    end

    def queue_counts
      @queue_counts ||= FILTERS.index_with { queued_blogs(it).count }
    end

    def queued_blogs(filter)
      blogs = Blog.awaiting_review

      case filter
      when "links" then with_external_links(blogs)
      when "screening" then blogs.where(users: { id: User::Screening.failed.select(:user_id) })
      else blogs
      end
    end

    def with_external_links(blogs)
      outside = "https?://(?!([^\"/?#:]*\\.)?#{Regexp.escape(Rails.application.config.x.domain)}([\"/?#:]|$))"
      linked = ActionText::RichText.where("action_text_rich_texts.body ~* ?", "href=\"#{outside}")

      bio = linked.where(record_type: "Blog", name: "bio").where("action_text_rich_texts.record_id = blogs.id")
      posts = linked.where(record_type: "Post", name: "content", record_id: Post.kept.where("posts.blog_id = blogs.id").select(:id))
      navigation = NavigationItem.where("navigation_items.blog_id = blogs.id").where("navigation_items.url ~* ?", "^#{outside}")

      blogs.where(bio.arel.exists).or(blogs.where(posts.arel.exists)).or(blogs.where(navigation.arel.exists))
    end
end
