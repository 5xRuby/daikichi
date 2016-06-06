Rails.application.routes.draw do
  scope "(:locale)", locale: /en/ do
    devise_for :users

    root 'pages#index'

    namespace :backend do
      resources :users
    end
  end
end
