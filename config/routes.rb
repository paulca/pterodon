Rails.application.routes.draw do
  resource :session
  get "/signin", to: "sessions#new"

  resource :profile

  resources :passwords, param: :token
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  root to: "home#index"

  resources :posts
  resource :redirect

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"

  get "@:username", to: "users#show", as: :user

  namespace :activity_pub do
    post "/shared_inbox", to: "shared_inbox#create"

    scope "/:username" do
      resource :actor, only: [ :show ]
      resource :inbox, only: [ :create ]
      resource :outbox, only: [ :show ]
      resources :followers, only: [ :index ]
      resources :following, only: [ :index ]
      resources :posts, only: [ :show ]
    end
  end

  # WebFinger route
  get "/.well-known/webfinger", to: "activity_pub/webfinger#show"
end
