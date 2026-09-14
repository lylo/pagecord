class App::Posts::TagsController < App::BaseController
  before_action :set_tag, only: [ :update, :destroy ]

  def index
    @tag_counts = posts.tag_counts
  end

  def update
    new_name = params[:new_name].to_s.strip.downcase

    unless new_name.match?(Taggable::VALID_TAG_FORMAT)
      return redirect_to app_posts_tags_path, alert: "Tags can only contain letters, numbers, and hyphens."
    end

    return redirect_to app_posts_tags_path if new_name == @tag

    posts.rename_tag(@tag, new_name)
    @blog.touch

    redirect_to app_posts_tags_path, notice: "Tag was renamed to #{new_name}"
  end

  def destroy
    posts.remove_tag(@tag)
    @blog.touch

    redirect_to app_posts_tags_path, notice: "Tag #{@tag} was removed from all posts"
  end

  private

    def set_tag
      @tag = params[:name].to_s.downcase
      raise ActiveRecord::RecordNotFound unless posts.tagged_with(@tag).exists?
    end

    def posts
      @blog.posts.kept
    end
end
