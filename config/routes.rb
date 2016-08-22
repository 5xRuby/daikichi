Rails.application.routes.draw do
  scope "(:locale)", locale: /en/ do
    devise_for :users

    root 'pages#index'

    namespace :backend do
      resources :users
      resources :employee_leave_times, only: [:index]
      resources :leave_applications, only: [:index, :update] do
        member do
          get 'verify'
        end
      end
    end
    resources :leave_applications, except: [:destroy] do
      member do
        put 'cancel'
      end
    end
  end
end
