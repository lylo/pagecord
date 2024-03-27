Rails.application.routes.draw do

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
    resources :users, only: [:update, :destroy]

    root "posts#index"
  end

  get '/@:username', to: redirect('/%{username}')

  scope ":username" do
    get "/", to: "users/posts#index", as: :user_posts
    get "/profile", to: "users/profile#show", as: :user_profile
    get "/:id", to: "users/posts#show", constraints: { id: /[0-9a-f]+/ }, as: :post_without_title
    get "/:title-:id", to: "users/posts#show", constraints: { id: /[0-9a-f]+/ }, as: :post_with_title
  end

  direct :post do |post, options|
    if post.url_title.present?
      post_with_title_path(post.user.username, post.url_title, post.url_id)
    else
      post_without_title_path(post.user.username, post.url_id)
    end
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  root "home#index"
end
