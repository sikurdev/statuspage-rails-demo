Rails.application.routes.draw do
  root "status_pages#show"

  resources :subscriptions, only: %i[ create destroy ], param: :token do
    member do
      get :confirm
      get :unsubscribe
    end
  end

  namespace :admin do
    root "monitors#index"
    resources :monitors do
      post :check, on: :member
    end
  end

  # Demo mailbox (letter_opener_web), behind the same admin credentials.
  mount Rack::Auth::Basic.new(LetterOpenerWeb::Engine, "Admin") { |user, password| AdminCredentials.valid?(user, password) },
    at: "/admin/mail"

  get "up" => "rails/health#show", as: :rails_health_check
end
