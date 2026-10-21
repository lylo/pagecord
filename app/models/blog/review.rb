# What the moderation queue shows for a blog awaiting review, loaded a page at a time.
class Blog::Review
  LATEST_POSTS = 3
  BURST_WINDOW = 15.minutes

  attr_reader :blog, :latest_posts, :published_count, :draft_count, :link_hosts, :burst_count

  delegate :user, to: :blog

  class << self
    def for(blogs)
      blog_ids = blogs.map(&:id)
      latest_posts = latest_posts_for(blog_ids).group_by(&:blog_id)
      counts = Post.kept.where(blog_id: blog_ids).group(:blog_id, :status).count
      post_hosts = post_hosts_for(blog_ids)
      bursts = burst_counts_for(blogs.map(&:user_id))

      blogs.map do |blog|
        new blog,
          latest_posts: latest_posts.fetch(blog.id, []),
          published_count: counts.fetch([ blog.id, "published" ], 0),
          draft_count: counts.fetch([ blog.id, "draft" ], 0),
          post_hosts: post_hosts.fetch(blog.id, {}),
          burst_count: bursts.fetch(blog.user_id, 0)
      end
    end

    def host_of(url)
      host = url.to_s[%r{\Ahttps?://(?:www\.)?([^/?#:]+)}i, 1]&.downcase
      host unless host.nil? || internal?(host)
    end

    private
      def latest_posts_for(blog_ids)
        ranked = Post.kept.published.where(blog_id: blog_ids)
          .select("posts.*, row_number() over (partition by blog_id order by published_at desc) as position")

        Post.from(ranked, :posts).where("position <= ?", LATEST_POSTS).order(:blog_id, :position)
          .includes(:blog, :content_moderation).to_a
      end

      # { blog_id => { post_id => { host => count } } } for every live post, drafts included.
      def post_hosts_for(blog_ids)
        rows = ActionText::RichText
          .joins("JOIN posts ON posts.id = action_text_rich_texts.record_id")
          .joins(%q{CROSS JOIN LATERAL regexp_matches(action_text_rich_texts.body, 'href="https?://(?:www\.)?([^"/?#:]+)', 'gi') AS link(host)})
          .where(record_type: "Post", name: "content", posts: { blog_id: blog_ids, discarded_at: nil })
          .group("posts.blog_id", "posts.id", "lower((link.host)[1])")
          .count

        rows.each_with_object({}) do |((blog_id, post_id, host), count), hosts|
          next if internal?(host)

          ((hosts[blog_id] ||= {})[post_id] ||= Hash.new(0))[host] += count
        end
      end

      # Other accounts created in the same timezone within BURST_WINDOW, deleted ones included.
      def burst_counts_for(user_ids)
        User.where(id: user_ids)
          .joins(User.sanitize_sql_array([ <<~SQL, { window: BURST_WINDOW.to_i } ]))
            JOIN users others ON others.id <> users.id
              AND others.timezone = users.timezone
              AND others.created_at BETWEEN users.created_at - make_interval(secs => :window)
                                        AND users.created_at + make_interval(secs => :window)
          SQL
          .group("users.id")
          .count
      end

      def internal?(host)
        domain = Rails.application.config.x.domain
        host == domain || host.end_with?(".#{domain}")
      end
  end

  def initialize(blog, latest_posts:, published_count:, draft_count:, post_hosts:, burst_count:)
    @blog = blog
    @latest_posts = latest_posts
    @published_count = published_count
    @draft_count = draft_count
    @post_hosts = post_hosts
    @burst_count = burst_count
    @link_hosts = tally_link_hosts
  end

  def hosts_for(post)
    @post_hosts.fetch(post.id, {})
  end

  def email_domain
    user.email.split("@").last
  end

  def empty?
    published_count.zero? && draft_count.zero? && blog.bio.blank?
  end

  def burst?
    burst_count >= 2
  end

  private
    def tally_link_hosts
      urls = [ *blog.bio.body&.links, *blog.navigation_items.filter_map(&:url) ]
      hosts = urls.filter_map { self.class.host_of(it) }.tally

      @post_hosts.each_value { |post_hosts| hosts.merge!(post_hosts) { |_host, a, b| a + b } }
      hosts.sort_by { |host, count| [ -count, host ] }.to_h
    end
end
