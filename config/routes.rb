Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  root "lists#index"

  resources :lists, only: [:index, :show, :new, :create] do
    resources :bookmarks, only: [:new, :create]
  end
  resources :bookmarks, only: [:destroy]
end
