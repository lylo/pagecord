module FreeTrial
  extend ActiveSupport::Concern

  included do
    before_action :free_trial_check
  end

  private

    def free_trial_check
      if Current.user && Current.user.free_trial_expired?
        flash[:error] = "Your free trial has expired"
        redirect_to app_subscriptions_path
      end
    end
end
