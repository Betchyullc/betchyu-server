Server::Application.routes.draw do

  resources :comments

  get 'bets/cleanup' => 'bets#cleanup'
  resources :updates

  resources :invites

  resources :bets do
    resources :invites
    resources :updates
    resources :comments
  end

  get 'user/:id' => 'user#show'
  put 'user/:id' => 'user#update'
  post 'user' => 'user#create'
  post 'card' => 'user#card'
  get 'card/:id' => 'user#show_card'
  put 'pay' => 'user#pay'

  # custom Bet routes
  get 'my-bets/:id' => 'bets#my_bets'
  get 'pending-bets/:id' => 'bets#pending'
  get 'friend-bets/:id' => 'bets#friend'
  get 'past-bets/:id' => 'bets#past'
  get 'achievements-count/:id' => 'bets#achievements_count'

  get 'analytics/standard' => 'analytics#standard'
  get 'analytics/standard_report' => 'analytics#standard'
  get 'analytics/demographics' => 'analytics#demographics'
  get 'analytics/demographics_report' => 'analytics#demographics'
  get 'analytics/daily_report' => 'analytics#daily'
  get 'analytics/daily' => 'analytics#daily'
  get 'analytics/buy' => 'analytics#need_to_buy'

  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  # root 'welcome#index'

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
end
