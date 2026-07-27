# Preview all emails at http://localhost:3000/rails/mailers/comment_mailer
class CommentMailerPreview < ActionMailer::Preview
  def digest
    CommentMailer.with(blog: blog, comments: waiting.first(3)).digest
  end

  # The intro pluralises, so the singular is worth seeing on its own
  def digest_with_one_comment
    CommentMailer.with(blog: blog, comments: waiting.first(1)).digest
  end

  private

    def blog
      @blog ||= Blog.find_by(subdomain: "joel") || Blog.first
    end

    def waiting
      blog.comments.pending.includes(:post).to_a.presence || samples
    end

    def samples
      post = blog.posts.visible.first

      [
        [ "Sarah", "Great post, the bit about waiting for the light resonated." ],
        [ "Tom", "Does this work with a 35mm lens, or do you need something wider?" ],
        [ "Priya", "Sent this to my camera club. Thanks for writing it up." ]
      ].map { |name, message| Post::Comment.new(post: post, name: name, message: message) }
    end
end
