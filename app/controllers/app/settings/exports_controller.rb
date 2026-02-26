class App::Settings::ExportsController < AppController
  rate_limit to: 5, within: 1.day, only: :create, with: :export_limit_reached

  def index
    @exports = @blog.exports
      .with_attached_file
      .order(created_at: :desc)
  end

  def create
    @export = @blog.exports.create!(export_params)
    BlogExportJob.perform_later(@export.id)

    redirect_to app_settings_exports_path, notice: "Export started"
  end

  def destroy
    @export = @blog.exports.find(params[:id])
    @export.destroy

    redirect_to app_settings_exports_path, notice: "Export deleted"
  end

  private

    def export_params
      params.fetch(:blog_export, {}).permit(:format)
    end

    def export_limit_reached
      redirect_to app_settings_exports_path, alert: "You've reached the limit of 5 exports per day. Please try again tomorrow."
    end
end
