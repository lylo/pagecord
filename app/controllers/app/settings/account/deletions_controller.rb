class App::Settings::Account::DeletionsController < App::BaseController
  def new
    @cancellation = Cancellation.new
  end

  def create
    @cancellation = Cancellation.new(cancellation_params.merge(user: Current.user, kind: :account, plan: Current.user.subscription&.plan))
    return render(:new, status: :unprocessable_entity) unless @cancellation.save

    DestroyUserJob.perform_later(Current.user.id)
    SendCancellationEmailJob.set(wait: 24.hours).perform_later(Current.user.id, subscriber: false)
    sign_out

    redirect_to root_path
  end

  private

    def cancellation_params
      params.expect(cancellation: [ :reason, :feedback ])
    end
end
