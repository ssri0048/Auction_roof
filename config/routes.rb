Rails.application.routes.draw do
  resource :session, only: %i[ new create destroy ]
  resource :registration, only: %i[ new create ]
  resource :password_reset, only: %i[ new create edit update ]

  get "geography/districts", to: "geography#districts", as: :geography_districts
  get "geography/sub_districts", to: "geography#sub_districts", as: :geography_sub_districts

  resource :onboarding, only: :show, controller: "onboarding"
  scope "onboarding", controller: "onboarding", constraints: { step: Regexp.union(User::ONBOARDING_STEPS) } do
    get ":step", action: :edit, as: :onboarding_step
    patch ":step", action: :update
  end

  resources :auctions, except: :destroy do
    get :calendar, on: :collection
    resources :bids, only: :create
    resources :chat_messages, only: %i[ create destroy ]
  end
  resources :notifications, only: :index do
    patch :read, on: :member
    post :read_all, on: :collection
  end

  namespace :admin do
    resources :onboardings, only: %i[ index show ] do
      post :review, on: :member
    end
    resources :auctions, only: :index do
      member do
        post :close
        post :cancel
      end
    end
    get "reports", to: "reports#index"
    resources :users, only: %i[ index show new create edit update ]
    resources :roles, only: %i[ index create edit update destroy ]
  end

  namespace :api do
    namespace :v1 do
      post "user", to: "users#create"
      get "me", to: "users#me"
      resource :session, only: %i[ create destroy ]
      resources :auctions, only: %i[ index show ] do
        resources :bids, only: :create
      end
    end
  end

  # Health check for load balancers / Railway
  get "up" => "rails/health#show", as: :rails_health_check

  get "login", to: "sessions#new"
  get "register", to: "registrations#new"
  get "forgot-password", to: "password_resets#new"

  root "home#index"
end
