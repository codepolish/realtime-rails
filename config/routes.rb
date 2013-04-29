RealtimeRails::Application.routes.draw do
  get 'chat' => 'chat#index'
  get 'draw' => 'draw#index'
  root 'home#show'
end
