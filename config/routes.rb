Rails.application.routes.draw do
  get "auth/:provider/callback", to: "sessions#create"
  get "auth/failure", to: "sessions#failure"
  delete "sign_out", to: "sessions#destroy", as: :sign_out

  resource :dashboard, only: :show
  resource :account, only: %i[show destroy]
  resources :favourites, only: :index, controller: "course_favourites"

  resources :courses, only: %i[index new create]

  scope "/courses/:github_owner/:github_repo",
        constraints: { github_owner: /[a-zA-Z0-9][a-zA-Z0-9\-]*/, github_repo: /[a-zA-Z0-9_][a-zA-Z0-9._\-]*/ } do
    get "", to: "courses#show", as: :course
    delete "", to: "courses#destroy"
    post "resubmit", to: "courses#resubmit", as: :resubmit_course
    post "track_load", to: "courses#track_load", as: :track_load_course
    post "favourite", to: "course_favourites#create", as: :favourite_course
    delete "favourite", to: "course_favourites#destroy"
  end

  get "privacy", to: "pages#privacy"
  get "terms", to: "pages#terms"
  get "authoring-guide", to: "pages#authoring_guide", as: :authoring_guide
  get "authoring-guide/skill", to: "pages#download_skill", as: :download_skill

  resolve("Course") { |course| route_for(:course, github_owner: course.github_owner, github_repo: course.github_repo) }

  get "up" => "rails/health#show", as: :rails_health_check

  root "courses#index"
end
