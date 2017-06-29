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

      resources :leave_times, except: [:edit, :update, :destroy] do
        post :append_quota, on: :collection
      end

      resources :bonus_leave_time_logs, only: [:index, :update]
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

    resources :leave_times, only: [:index, :show]
    resources :remote, only: [:new, :create, :update, :edit]
  end
end
