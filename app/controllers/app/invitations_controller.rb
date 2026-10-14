class App::InvitationsController < App::BaseController
  def index
    @invitations = Current.user.invitations.includes(invitee: :blogs).order(created_at: :desc)
  end

  def create
    Current.user.invitations.create! if Current.user.invitations_remaining.positive?
    redirect_to app_invitations_path
  end
end
