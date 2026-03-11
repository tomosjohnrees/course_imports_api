Rails.application.routes.draw do
  get "auth/:provider/callback", to: "sessions#create"
  get "auth/failure", to: "sessions#failure"
  delete "sign_out", to: "sessions#destroy", as: :sign_out

  resource :dashboard, only: :show
  resource :account, only: %i[show destroy]

  resources :courses, only: %i[index new create show destroy] do
    post :resubmit, on: :member
  end

  get "privacy", to: "pages#privacy"
  get "terms", to: "pages#terms"

  get "up" => "rails/health#show", as: :rails_health_check

  root "courses#index"
end
