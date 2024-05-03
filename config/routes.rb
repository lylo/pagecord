require "sidekiq/web"

class SidekiqAdminConstraint
  def matches?(request)
    if current_user = User.kept.find(request.session[:user_id])
      ENV["ADMIN_USERNAME"] == current_user.username &&
      ENV["ADMIN_DELIVERY_EMAIL"] == current_user.delivery_email
    else
      false
    end
  rescue
    false
  end
end

module DomainConstraints
  def self.custom_domain?(request)
    !default_domain?(request)
  end

  # FIX ME: This is duplicated in RoutingHelper - needs to go in a class
  def self.default_domain?(request)
    if Rails.env.production?
      request.host == "pagecord.com"
    elsif Rails.env.test?
      request.host =~ /\.example\.com/
    else
      request.host == "localhost"
    end
  end
end

Rails.application.routes.draw do
  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  constraints SidekiqAdminConstraint.new do
    mount Sidekiq::Web => '/admin/sidekiq'
  end

  get "/404", to: "errors#not_found"
  get "/422", to: "errors#unacceptable"
  get "/500", to: "errors#internal_error"

  resources :signups, only: [:index, :new, :create] do
    get :thanks, on: :collection
  end

  get "/login", to: "sessions#new"
  delete "/logout", to: "sessions#destroy"
  resources :sessions, only: [:create] do
    get :thanks, on: :collection
  end

  get "/verify/:token", to: "access_requests#verify", as: :verify_access_request

  # Defines the routes for the resources of the model Post
  get "/terms", to: "public#terms", as: :terms
  get "/privacy", to: "public#privacy", as: :privacy
  get "/faq", to: "public#faq", as: :faq

  namespace :app do
    resources :posts, only: [:index, :destroy]
    resources :users, only: [:update, :destroy] do
      post :follow, to: 'followings#create'
      delete :unfollow, to: 'followings#destroy'
    end
    resources :followings, only: [:index]

    get "/account", to: "account#index"
    get "/feed", to: "feed#index"
    get "/feed/rss/:token", to: "feed#private_rss", as: :private_rss_feed, format: :rss

    root "feed#index"
  end

  get "/admin", to: "admin#index", as: :admin
  namespace :admin do
    resources :stats, only: [:index]
    resources :posts, only: [:index]
  end

  constraints(DomainConstraints.method(:custom_domain?)) do
    get "/", to: "users/posts#index", as: :custom_user_posts
    get "/:id", to: "users/posts#show", constraints: { id: /[0-9a-f]+/ }, as: :custom_post_without_title
    get "/:title-:id", to: "users/posts#show", constraints: { id: /[0-9a-f]+/ }, as: :custom_post_with_title
    get "/:username.rss", to: "users/posts#index", format: :rss, as: :custom_user_posts_rss
  end

  constraints(DomainConstraints.method(:default_domain?)) do
    get '/@:username', to: redirect('/%{username}')

    scope ":username" do
      get "/", to: "users/posts#index", as: :user_posts
      get "/:id", to: "users/posts#show", constraints: { id: /[0-9a-f]+/ }, as: :post_without_title
      get "/:title-:id", to: "users/posts#show", constraints: { id: /[0-9a-f]+/ }, as: :post_with_title
    end
  end

  direct :rails_public_blob do |blob|
    # Preserve the behaviour of `rails_blob_url` inside these environments
    # where S3 or the CDN might not be configured
    if ENV.fetch("ACTIVE_STORAGE_ASSET_HOST", false) && blob&.key
     File.join(ENV.fetch("ACTIVE_STORAGE_ASSET_HOST"), blob.key)
    else
     route =
        # ActiveStorage::VariantWithRecord was introduced in Rails 6.1
       # Remove the second check if you're using an older version
       if blob.is_a?(ActiveStorage::Variant) || blob.is_a?(ActiveStorage::VariantWithRecord)
          :rails_representation
       else
          :rails_blob
       end
     route_for(route, blob)
    end
  end

  # Defines the root path route ("/")
  root "home#index"
end
