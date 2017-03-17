Rails.application.routes.draw do
  scope "(:locale)", locale: /en/ do
    devise_for :users, controllers: { registrations: "users/registrations" }

    root "pages#index"

    namespace :backend do
      resources :users

      resources :leave_applications, only: [:index, :update] do
        get :verify, on: :member
        get :statistics, on: :collection
      end

      resources :leave_times, except: [:show]

      resources :bonus_leave_time_logs, only: [:index, :update]

      get "monthly_leave_times",
        to: "monthly_leave_times#index",
        as: "monthly_leave_times"
    end

    resources :leave_applications, except: [:destroy] do
      member do
        put "cancel"
      end

      collection do
        get "/:status", to: "leave_applications#index",
                        constraints: { status: /pending|approved|rejected|canceled/ }
      end
    end

    resources :leave_times, only: [:index]

    get "leave_time/:type",
      to: "leave_times#show",
      as: "leave_time"
  end
end
