Rails.application.routes.draw do
  resources :users, only: [:new, :create]

  get "/login", to: "sessions#new"
  delete "/logout", to: "sessions#destroy"
  resources :sessions, only: [:create] do
    get :thanks, on: :collection
  end

  get "/verify/:token", to: "access_requests#verify", as: :verify_access_request

  # Defines the routes for the resources of the model Post
  get "/terms", to: "public#terms", as: :terms
  get "/privacy", to: "public#privacy", as: :privacy

  namespace :app do
    resources :posts, only: [:index, :destroy]

    root "posts#index"
  end

  scope ":username" do
    get "/", to: "posts#index", as: :user_posts
    get "/:title-:id", to: "posts#show", as: :post
  end

  direct :post do |post, options|
    "/#{post.user.username}/#{post.url_title}-#{post.url_id}"
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  root "home#index"
end
