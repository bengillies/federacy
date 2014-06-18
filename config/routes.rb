Rails.application.routes.draw do

  devise_for :users

  get 'profiles/:id', to: 'profiles#show', as: 'profile'

  resources :spaces do
    resources :members
    resources :tiddlers do
      resources :revisions
    end
  end

  root to: "spaces#index"

end
