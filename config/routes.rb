Rails.application.routes.draw do
  root "events#index"
  get "login", to: "sessions#new"
  post "auth/discord", to: "discord_sessions#new", as: :discord_login
  get "auth/discord/callback", to: "discord_sessions#create", as: :discord_callback

  resources :sessions, only: %i[destroy]
  resources :events do
    resources :participations, only: %i[create destroy]
    scope module: :events do
      resources :cancellations, only: %i[create]
    end
  end
  resource :user
end
