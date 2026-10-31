class Api::InvitationsController < Api::BaseController
  def create
    user = Current.blog.user
    raise Api::ForbiddenError, "No invite codes left" unless user.invitations_remaining.positive?

    invitation = user.invitations.create!
    render json: { code: invitation.code, url: new_signup_url(code: invitation.code, host: Rails.application.config.x.domain) }, status: :created
  end
end
