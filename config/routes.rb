require "sidekiq/web"

class SidekiqAdminConstraint
  def matches?(request)
    if current_user = User.kept.find(request.session[:user_id])
      ENV["ADMIN_USERNAME"] == current_user.username &&
      # FIXME this should be a password
      ENV["ADMIN_DELIVERY_EMAIL"] == current_user.blog.delivery_email
    else
      false
    end
  rescue
    false
  end
end

module DomainConstraints
  def self.custom_domain?(request)
    if Rails.env.production?
      request.host != "pagecord.com"
    elsif Rails.env.test?
      request.host !~ /\.example\.com/ && request.host != "127.0.0.1"  # 127.0.0.1 used by Capybara
    else
      request.host != "localhost"
    end
  end

  def self.default_domain?(request)
    !custom_domain?(request)
  end
end

module Constraints
  class RssFormat
    def matches?(request)
      request.format.rss?
    end
  end
end

Rails.application.routes.draw do
  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up", to: "rails/health#show", as: :rails_health_check

  constraints SidekiqAdminConstraint.new do
    mount Sidekiq::Web, at: "/admin/sidekiq"
  end

  get "/404", to: "errors#not_found"
  get "/422", to: "errors#unacceptable"
  get "/500", to: "errors#internal_error"

  resources :signups, only: [ :index, :new, :create ] do
    get :thanks, on: :collection
  end

  namespace :billing do
    resources :paddle_events, only: [ :create ]

    post "/paddle/create_update_payment_method_transaction", to: "paddle#create_update_payment_method_transaction"
  end


  get "/login", to: "sessions#new"
  delete "/logout", to: "sessions#destroy"
  resources :sessions, only: [ :create ] do
    get :thanks, on: :collection
  end

  get "/verify/:token", to: "access_requests#verify", as: :verify_access_request

  # Defines the routes for the resources of the model Post
  get "/terms", to: "public#terms", as: :terms
  get "/privacy", to: "public#privacy", as: :privacy
  get "/faq", to: "public#faq", as: :faq
  get "/pagecord-vs-hey-world", to: "home#pagecord_vs_hey_world"

  namespace :app do
    resources :posts

    resources :settings, only: [ :index ]

    namespace :settings do
      resources :users, only: [ :index, :update, :destroy ]
      resources :blogs, only: [ :index, :update ]

      get "/account/edit", to: "account#edit"

      resources :subscriptions, only: [ :index, :destroy ] do
        get :thanks, on: :collection
        get :cancel_confirm, on: :collection
      end
    end

    resources :blogs do
      post :follow, to: "followings#create"
      delete :unfollow, to: "followings#destroy"
    end

    resources :followings, only: [ :index ]

    get "/account", to: "account#index"

    get "/feed", to: "feed#index"
    get "/feed/rss/:token", to: "feed#private_rss", as: :private_rss_feed, format: :rss

    root "posts#index"
  end

  get "/admin", to: "admin#index", as: :admin
  namespace :admin do
    resources :stats, only: [ :index ]
    resources :posts, only: [ :index ]
    resources :users, only: [ :destroy ]
  end

  constraints(DomainConstraints.method(:custom_domain?)) do
    get "/", to: "blogs/posts#index", as: :custom_blog_posts
    get "/:token", to: "blogs/posts#show", constraints: { token: /[0-9a-f]+/ }, as: :custom_post_without_title
    get "/:title-:token", to: "blogs/posts#show", constraints: { token: /[0-9a-f]+/ }, as: :custom_post_with_title
    get "/:username", to: "blogs/posts#index", constraints: Constraints::RssFormat.new, as: :custom_blog_posts_rss
  end

  constraints(DomainConstraints.method(:default_domain?)) do
    get "/@:username", to: redirect("/%{username}")

    scope ":username" do
      get "/", to: "blogs/posts#index", as: :blog_posts
      get "/:token", to: "blogs/posts#show", constraints: { token: /[0-9a-f]+/ }, as: :post_without_title
      get "/:title-:token", to: "blogs/posts#show", constraints: { token: /[0-9a-f]+/ }, as: :post_with_title
    end
  end

  namespace :api do
    post "embeds/bandcamp", to: "embeds#bandcamp"
  end

  direct :rails_public_blob do |blob|
    # Preserve the behaviour of `rails_blob_url` inside these environments
    # where S3 or the CDN might not be configured
    if ENV.fetch("ACTIVE_STORAGE_ASSET_HOST", false) && blob&.key
     File.join(ENV.fetch("ACTIVE_STORAGE_ASSET_HOST"), blob.key)
    else
      route =
        # ActiveStorage::VariantWithRecord was introduced in Rails 6.1
        # Remove the second check if you"re using an older version
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
