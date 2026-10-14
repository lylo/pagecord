module User::Invitable
  extend ActiveSupport::Concern

  SUBSCRIBER_INVITATIONS = 10
  WRITER_INVITATIONS = 3

  included do
    has_many :invitations, foreign_key: :inviter_id, inverse_of: :inviter, dependent: :destroy
    has_one :invitation, foreign_key: :invitee_id, inverse_of: :invitee, dependent: :nullify
  end

  def invited?
    invitation.present?
  end

  def invitations_remaining
    [ invitation_allowance - invitations.size, 0 ].max
  end

  private

    def invitation_allowance
      if admin?
        Float::INFINITY
      elsif subscribed?
        SUBSCRIBER_INVITATIONS
      elsif writing_regularly?
        WRITER_INVITATIONS
      else
        0
      end
    end

    def writing_regularly?
      created_at.before?(30.days.ago) && Post.posts.visible.where(blog: blogs).distinct.count("DATE(posts.created_at)") >= 4
    end
end
