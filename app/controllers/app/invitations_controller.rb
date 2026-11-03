class App::InvitationsController < App::BaseController
  include Pagy::Method

  before_action -> { redirect_to app_posts_path unless Current.user.inviting? }

  def index
    @pagy, @invitations = pagy(Current.user.invitations.includes(invitee: :blogs).order(redeemed_at: :desc, created_at: :desc), limit: 25)
  end

  def create
    Current.user.invitations.create! if Current.user.invitations_remaining.positive?
    redirect_to app_invitations_path
  end

  def destroy
    Current.user.invitations.available.find(params[:id]).destroy
    redirect_to app_invitations_path
  end
end
