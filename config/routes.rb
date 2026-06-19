Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Story 1.3: Authentication routes
  # OmniAuth callback is GET because IdP redirects back with GET after auth
  get  "/auth/:provider/callback", to: "sessions#create", as: :auth_callback
  get  "/auth/failure",            to: "sessions#failure", as: :auth_failure
  get  "/sign_in",                 to: "sessions#new",    as: :new_session
  delete "/sign_out",              to: "sessions#destroy", as: :sign_out

  # Temporary protected root — will be replaced in Story 2.x or 1.5 with a real dashboard.
  # Protected by ApplicationController#require_authentication — unauthenticated requests
  # are redirected to new_session_path.
  root to: "home#index"
end
