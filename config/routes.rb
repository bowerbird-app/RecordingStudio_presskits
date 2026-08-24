# frozen_string_literal: true

# User slice for press kits. Hosts mount this engine, then people work from
# the index and kit editor. Admin screens register separately.
RecordingStudioPresskits::Engine.routes.draw do
  resources :press_kits, only: %i[index show new create edit update] do
    member do
      get :preview
    end
    resources :sections, only: %i[create destroy]
    resource :order, only: :update, controller: "orders"
  end

  root to: "press_kits#index"
end
