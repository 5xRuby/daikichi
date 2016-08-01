Rails.application.routes.draw do
  scope "(:locale)", locale: /en/ do
    devise_for :users

    root 'pages#index'

    namespace :backend do
      resources :users
      get 'leave_applications', to: "leave_applications#index", as: "leave_applications"
    end
    resources :leave_applications
  end
end
