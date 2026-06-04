class App::Blogs::TrashController < AppController
  before_action :require_multiple_blogs

  def show
    @trashed_blogs = Current.user.all_blogs.discarded.order(discarded_at: :desc)
  end

  def destroy
    Current.user.all_blogs.discarded.destroy_all
    redirect_to app_blogs_trash_path, notice: "Trash was successfully emptied"
  end

  private

    def require_multiple_blogs
      redirect_to app_root_path unless current_features.enabled?(:multiple_blogs)
    end
end
