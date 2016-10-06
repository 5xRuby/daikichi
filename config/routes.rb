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

        collection do
          get '/:status', to: 'leave_applications#index',
                          constraints: { status: /pending|approved|rejected|canceled/ }
        end
      end

      resources :leave_times, only: [:index, :edit, :update]

      get 'monthly_leave_times/:year/:month', to: 'monthly_leave_times#index', as: "monthly_leave_times"
    end

    resources :leave_applications, except: [:destroy] do
      member do
        put 'cancel'
      end

      collection do
        get '/:status', to: 'leave_applications#index',
                        constraints: { status: /pending|approved|rejected|canceled/ }
      end
    end

    resources :leave_times, only: [:index]

    get 'leave_time/:type',
      to: "leave_times#show",
      constraints: { type: /annual|bonus|personal|sick/ },
      as: "leave_time"
  end
end
