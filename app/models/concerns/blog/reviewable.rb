module Blog::Reviewable
  extend ActiveSupport::Concern

  included do
    before_create -> { self.reviewed_at = Time.current }, if: -> { user.subscribed? }

    scope :awaiting_review, -> { kept.with_kept_user.where(reviewed_at: nil).reviewable }
  end

  class_methods do
    # Blogs with something on them to review: a published post, bio text, a navigation link or a custom footer.
    def reviewable
      posts = Post.kept.published.where("posts.blog_id = blogs.id")
      navigation = NavigationItem.where("navigation_items.blog_id = blogs.id")
      bio = ActionText::RichText.where(record_type: "Blog", name: "bio").where("action_text_rich_texts.record_id = blogs.id")
        .where("regexp_replace(action_text_rich_texts.body, '<[^>]*>|&nbsp;|\\s', '', 'g') <> ''")

      where(posts.arel.exists).or(where(navigation.arel.exists)).or(where(bio.arel.exists)).or(where.not(custom_footer_html: [ nil, "" ]))
    end
  end

  def search_indexable?
    reviewed_at.present? || user.subscribed?
  end

  def reviewable?
    Blog.reviewable.exists?(id)
  end
end
