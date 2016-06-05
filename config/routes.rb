Rails.application.routes.draw do
  devise_for :users

  namespace :backend do
    resources :users
  end
end
