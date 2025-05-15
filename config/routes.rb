require "sidekiq/web"

class SidekiqAdminConstraint
  def matches?(request)
    if current_user = User.kept.find(request.session[:user_id])
      ENV["ADMIN_USERNAME"] == current_user.blog.name &&
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
      request.host != Rails.application.config.x.domain
    elsif Rails.env.test?
      request.host !~ /\.example\.com/ && request.host != "127.0.0.1"  # 127.0.0.1 used by Capybara
    else
      ![ "localhost", "ant-evolved-equally.ngrok-free.app" ].include?(request.host)
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

  namespace :app do
    resources :posts
    resources :settings, only: [ :index ]

    resource :onboarding, only: [ :show, :update ], path: "onboarding" do
      member do
        post :complete
      end
    end

    namespace :settings do
      resources :audience, only: [ :index ]
      resources :users, only: [ :update, :destroy ]
      resources :blogs, only: [ :index, :update ]
      resources :appearance, only: [ :index, :update ]
      resources :email_subscribers, only: [ :index ]
      resources :email_change_requests, only: [ :create, :destroy ] do
        member do
          post :resend
        end
        collection do
          get "verify/:token", to: "email_change_requests#verify", as: :verify
        end
      end
      resources :exports

      get "/account/edit", to: "account#edit"

      resources :subscriptions, only: [ :index, :destroy ] do
        get :thanks, on: :collection
        get :cancel_confirm, on: :collection
      end
    end

    resources :blogs do
      resource :avatar, only: [ :destroy ], controller: "blogs/avatars"

      resources :social_links, only: [ :new ], controller: "blogs/social_links"

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
    resources :users, only: [ :show, :destroy ] do
      member do
        post :restore
      end
    end
  end

  shared_blog_routes = lambda do
    get "/robots.txt", to: "blogs/robots#show", as: :blog_robots, format: :text
    get "/sitemap.xml", to: "blogs/sitemaps#show", as: :blog_sitemap, format: :xml
    get "/", to: "blogs/posts#index", as: :blog_posts
    get "/feed.xml", to: "blogs/posts#index", defaults: { format: :rss }, as: :blog_feed_xml
    get "/feed", to: "blogs/posts#index", defaults: { format: :rss }, as: :blog_feed
    get "/:token", to: "blogs/posts#show", constraints: { token: /[0-9a-f]+/ }, as: :post_without_title
    get "/:title-:token", to: "blogs/posts#show", constraints: { token: /[0-9a-f]+/ }, as: :post_with_title

    resources :email_subscribers, controller: "blogs/email_subscribers", only: [ :create, :destroy ]

    get "/email_subscribers/:token/confirm", to: "blogs/email_subscribers/confirmations#show", as: :email_subscriber_confirmation
    get "/email_subscribers/:token/unsubscribe", to: "blogs/email_subscribers/unsubscribes#show", as: :email_subscriber_unsubscribe
    post "/email_subscribers/:token/unsubscribe", to: "blogs/email_subscribers/unsubscribes#create"

    resources :posts, only: [] do
      resources :upvotes, only: [ :create, :destroy ], module: :posts
      resources :replies, only: [ :new, :create ], module: :posts
    end
  end

  constraints(DomainConstraints.method(:custom_domain?)) do
    scope as: :custom, &shared_blog_routes
    get "/:name", to: "blogs/posts#index", constraints: Constraints::RssFormat.new, as: :custom_posts_rss
  end

  constraints(DomainConstraints.method(:default_domain?)) do
    get "/sitemap.xml", to: "public#sitemap", as: :public_sitemap, format: :xml
    get "/robots.txt", to: "public#robots", as: :robots, format: :text
    get "/terms", to: "public#terms", as: :terms
    get "/privacy", to: "public#privacy", as: :privacy
    get "/faq", to: "public#faq", as: :faq
    get "/pagecord-vs-hey-world", to: "public#pagecord_vs_hey_world"
    get "/blogging-by-email", to: "public#blogging_by_email"

    get "/@:name", to: redirect("/%{name}")
    scope ":name", &shared_blog_routes
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
