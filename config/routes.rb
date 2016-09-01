Rails.application.routes.draw do
  scope "(:locale)", locale: /en/ do
    devise_for :users

    root 'pages#index'

    namespace :backend do
      resources :users
      resources :leave_applications, only: [:index, :update] do
        member do
          get 'verify'
        end
      end
      get 'employee_leave_times/:year/:month', to: 'employee_leave_times#index', as: "employee_leave_times"
    end
    resources :leave_applications, except: [:destroy] do
      member do
        put 'cancel'
      end
    end
  end
end
