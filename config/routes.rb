Rails.application.routes.draw do
  get "auth/:provider/callback", to: "sessions#create"
  get "auth/failure", to: "sessions#failure"
  delete "sign_out", to: "sessions#destroy", as: :sign_out

  get "up" => "rails/health#show", as: :rails_health_check

  root "rails/health#show"
end
