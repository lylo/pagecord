class Admin::SuppressedEmailsController < AdminController
  include Pagy::Method

  def index
    scope = Email::Suppression.order(suppressed_at: :desc)
    scope = scope.where(reason: params[:reason]) if params[:reason].in?(%w[bounce complaint])

    @pagy, @suppressions = pagy(scope, limit: 25)
    @total_count = Email::Suppression.count
    @bounce_count = Email::Suppression.bounces.count
    @complaint_count = Email::Suppression.complaints.count
  end

  def destroy
    suppression = Email::Suppression.find(params[:id])
    suppression.destroy!
    redirect_to admin_suppressed_emails_path, notice: "#{suppression.email} has been unsuppressed"
  end
end
