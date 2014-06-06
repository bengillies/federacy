Rails.application.routes.draw do

  resources :spaces do
    resources :tiddlers do
      resources :revisions
    end
  end

end
