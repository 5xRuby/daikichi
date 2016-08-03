Rails.application.routes.draw do
  scope "(:locale)", locale: /en/ do
    devise_for :users

    root 'pages#index'

    namespace :backend do
      resources :users
      resources :leave_applications, only: [:index] do
        member do
          get 'verify'
          put 'approve'
          put 'reject'
        end
      end
    end
    resources :leave_applications, except: [:destroy]
  end
end
