class Api::InvitationsController < Api::BaseController
  def create
    user = Current.blog.user
    raise Api::ForbiddenError, "Invite codes can only be created in Settings" unless user.admin?

    invitation = user.invitations.create!
    render json: { code: invitation.code, url: new_signup_url(code: invitation.code, host: Rails.application.config.x.domain) }, status: :created
  end
end
