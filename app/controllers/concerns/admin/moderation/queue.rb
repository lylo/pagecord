module Admin::Moderation::Queue
  extend ActiveSupport::Concern

  FILTERS = %w[ all posts links screening unverified ].freeze

  included do
    helper_method :queue_filter, :queue_counts
  end

  private
    def queue_filter
      params[:filter].presence_in(FILTERS) || "all"
    end

    def queue_counts
      @queue_counts ||= FILTERS.index_with { queued_blogs(it).count }
    end

    def queued_blogs(filter)
      blogs = Blog.unreviewed

      case filter
      when "posts" then blogs.where(Post.kept.published.where("posts.blog_id = blogs.id").arel.exists)
      when "links" then with_external_links(blogs)
      when "screening" then blogs.where(users: { id: User::Screening.failed.select(:user_id) })
      when "unverified" then blogs.where(users: { verified: false })
      else blogs
      end
    end

    def with_external_links(blogs)
      outside = "https?://(?![^\"/]*#{Regexp.escape(Rails.application.config.x.domain)})"
      linked = ActionText::RichText.where("action_text_rich_texts.body ~* ?", "href=\"#{outside}")

      bio = linked.where(record_type: "Blog", name: "bio").where("action_text_rich_texts.record_id = blogs.id")
      posts = linked.where(record_type: "Post", name: "content", record_id: Post.kept.where("posts.blog_id = blogs.id").select(:id))
      navigation = NavigationItem.where("navigation_items.blog_id = blogs.id").where("navigation_items.url ~* ?", "^#{outside}")

      blogs.where(bio.arel.exists).or(blogs.where(posts.arel.exists)).or(blogs.where(navigation.arel.exists))
    end

    def respond_reviewed(blog, notice)
      respond_to do |format|
        format.turbo_stream do
          @blog = blog
          flash.now[:notice] = notice
          render "admin/moderation/blogs/reviewed"
        end
        format.html { redirect_back fallback_location: admin_moderation_blogs_path, notice: notice }
      end
    end
end
