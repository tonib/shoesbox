Rails.application.routes.draw do

  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # Music player
  resource :player , only: [ :index ] do
    # Action to execute commands on the music server with a get
    get 'music_cmd'  => 'player#music_cmd'
    # Action to execute commands on the music server with a post
    post 'music_cmd_post' => 'player#music_cmd'
    # Load the next page of songs
    get 'load_page' => 'player#load_page'
    # Change the current play list
    get 'change_play_list' => 'player#change_play_list'
    # Suggest names
    get 'suggest' => 'player#suggest'
  end

  # Work with songs
  resources :songs do
    # Load the next page of songs
    get 'load_page' , on: :collection
    # Run a music server command on available songs
    get 'music_cmd', on: :collection
    # Add songs to the reproduction queue
    get  'add_to_queue', on: :collection
    post 'add_to_queue', on: :collection
    # Edit multiple songs
    get 'edit_multiple', on: :collection
    # Update multiple songs
    post 'update_multiple', on: :collection
    # Download one song
    get 'download'
    # Download multiple songs
    get 'download_multiple', on: :collection
    # Download playlist
    get 'download_playlist', on: :collection
    # Delete multiple songs
    post 'delete_multiple', on: :collection
    # Suggest names
    get 'suggest' , on: :collection
    # Download Excel with songs info
    get 'excel' , on: :collection
  end

  # Work with artists
  resources :artists , only: [ :index , :edit , :update , :show ] do
    # Search text on wikipedia
    get 'search_wikipedia' , on: :collection
    # Get a wikipedia article main image
    get 'get_wikipedia_image' , on: :collection
    # Load next page of artist
    get 'load_page' , on: :collection
    # Join an artist to another
    post 'join'
    # Suggest names
    get 'suggest' , on: :collection
    # Add artists songs to queue
    post 'add_to_queue', on: :collection
    # Download playlist
    get 'download_playlist', on: :collection
    # Download multiple songs
    get 'download_multiple', on: :collection
  end

  # Work with albums
  resources :albums , only: [ :index , :show , :edit , :update ] do
    # Suggest names
    get 'suggest' , on: :collection
    # Load next page of albums
    get 'load_page' , on: :collection
    # Suggest names
    get 'suggest' , on: :collection
    # Add artists songs to queue
    post 'add_to_queue', on: :collection
    # Download playlist
    get 'download_playlist', on: :collection
  end

  # Work with play lists
  resources :play_lists

  # Work with radios
  resources :radios do
    get 'create_spanish_radios', on: :collection
  end

  # Work with running tasks
  resources :tasks , only: [ :index , :new , :create ]

  # Application settings
  resource :setting , only: [ :edit , :update ] do
    # Speech form
    post 'speech'
    # Recalculate metadata
    get 'recalculate_metadata'
    # Start the music service
    get 'start_music_service'
    # Stop the music service
    get 'stop_music_service'
    # Shutdown the device
    get 'shutdown'
    # Mount usb drive
    get 'mount_usb_drive'
  end

  # Other tools
  resource :tools , only: [] do
    # Get youtube song form
    get 'youtube', on: :collection
    # Get youtube audio
    post 'get_youtube', on: :collection
    # Show repeated songs
    get 'duplicated_songs', on: :collection
    # Show the readme
    get 'readme' , on: :collection
  end

  # Log viewer
  resources :logs , only: [ :index , :show ] do
    # Load the next page of logs
    get 'load_page' , on: :collection
    # Clear the log
    post 'clear' , on: :collection
  end

  # The application root
  root 'player#index'

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
