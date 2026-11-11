Rails.application.routes.draw do
  resource :session, only: %i[ new create destroy ]
  resource :registration, only: %i[ new create ]
  resource :password_reset, only: %i[ new create edit update ]

  namespace :admin do
    resources :users, only: %i[ index show edit update ]
    resources :roles, only: %i[ index create edit update destroy ]
  end

  namespace :api do
    namespace :v1 do
      post "user", to: "users#create"
      get "me", to: "users#me"
      resource :session, only: %i[ create destroy ]
    end
  end

  # Health check for load balancers / Railway
  get "up" => "rails/health#show", as: :rails_health_check

  get "login", to: "sessions#new"
  get "register", to: "registrations#new"
  get "forgot-password", to: "password_resets#new"

  root "home#index"
end
