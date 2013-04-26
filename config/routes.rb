RealtimeRails::Application.routes.draw do
  get 'chat' => 'chat#index'
  root 'home#show'
end
