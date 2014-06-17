Rails.application.routes.draw do

  devise_for :users

  resources :spaces do
    resources :tiddlers do
      resources :revisions
    end
  end

  root to: "spaces#index"

end
