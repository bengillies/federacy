Rails.application.routes.draw do

  devise_for :users

  get 'profiles/:id', to: 'profiles#show', as: 'profile'

  resources :spaces do
    resources :members

    get 't/:tiddler_title', to: 'short_links#show_tiddler', as: 'short_tiddler'

    resources :tiddlers do
      resources :revisions do
        resources :links
      end
      resources :links
      resources :backlinks
    end
  end

  get 's/:space_name', to: 'short_links#show_space', as: 'short_space'
  get 's/:space_name/:tiddler_title', to: 'short_links#show_space_tiddler', as: 'short_space_tiddler'
  get 'u/:user_name/:space_name', to: 'short_links#show_user_space', as: 'short_user_space'
  get 'u/:user_name/:space_name/:tiddler_title', to: 'short_links#show_user_space_tiddler', as: 'short_user_space_tiddler'

  root to: "spaces#index"

end
