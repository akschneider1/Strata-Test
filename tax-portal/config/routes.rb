# frozen_string_literal: true

Rails.application.routes.draw do
  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "health" => "rails/health#show", as: :rails_health_check
  get "up" => "rails/health#show"

  # Support locale prefixes for these routes:
  localized do
    # Defines the root path route ("/")
    root "home#index"

    # Session management
    devise_for :users, controllers: { sessions: "users/sessions" }
    devise_scope :user do
      get "sessions/challenge" => "users/sessions#challenge", as: :session_challenge
      post "sessions/challenge" => "users/sessions#respond_to_challenge", as: :respond_to_session_challenge
    end

    # Registration and account management
    namespace :users do
      resources :registrations, only: [ :create ]
      get "registrations" => "registrations#new", as: :new_registration

      resources :mfa, only: [ :new, :create ]
      get "mfa/preference" => "mfa#preference", as: :mfa_preference
      post "mfa/preference" => "mfa#update_preference", as: :update_mfa_preference
      delete "mfa" => "mfa#destroy", as: :disable_mfa

      get "forgot-password" => "passwords#forgot"
      post "forgot-password" => "passwords#send_reset_password_instructions"
      get "reset-password" => "passwords#reset"
      post "reset-password" => "passwords#confirm_reset"

      get "verify-account" => "registrations#new_account_verification"
      post "verify-account" => "registrations#create_account_verification"
      post "resend-verification" => "registrations#resend_verification_code"

      get "account" => "accounts#edit"
      patch "account/email" => "accounts#update_email"
    end

    # Taxpayer portal: the Colorado individual income tax return
    resources :tax_returns, only: [ :index, :create, :show ] do
      member do
        # One edit/update route per interview page
        TaxReturnFlow.pages.each do |page|
          get page.edit_pathname
          patch page.update_pathname
        end

        get :summary
        get :review
        patch :submit
        patch :respond
      end

      resources :dependents, only: [ :new, :create, :edit, :update, :destroy ]
      resources :income_documents, only: [ :new, :create, :edit, :update, :destroy ] do
        member do
          patch :confirm
          patch :dispute
        end
      end
    end

    # Development sandbox
    namespace :dev do
      get "sandbox"
      post "send_email"
    end
  end

  # One-click sign-in as a seeded person (demo mode only; see DemoMode)
  post "demo/sign_in" => "demo_sessions#create", as: :demo_sign_in
  delete "demo/sign_out" => "demo_sessions#destroy", as: :demo_sign_out

  # Examiner portal
  get "staff", to: "staff#index"
  scope path: "/staff" do
    resources :tax_return_cases, path: "returns", only: [ :index, :show ] do
      collection do
        get :closed
      end
      member do
        patch :assign_to_me
        patch :approve
        post :adjust
        post :request_information
        post :add_note
      end
    end

    # Work queue, from the Strata SDK
    resources :tasks, only: [ :index, :show, :update ] do
      collection do
        post :pick_up_next_task
      end
    end
  end

  mount Lookbook::Engine, at: "/lookbook" if ENV["ENABLE_LOOKBOOK"].present?
end
