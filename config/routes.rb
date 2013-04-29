RealtimeRails::Application.routes.draw do
  get 'chat' => 'chat#index'
  get 'draw' => 'draw#index'
  get 'time' => 'time#index'
  root 'home#show'
end
