# frozen_string_literal: true

# User slice for press kits. Hosts mount this engine, then people work from
# the index and kit editor. Admin screens register separately.
# rubocop:disable Metrics/BlockLength
RecordingStudioPresskits::Engine.routes.draw do
  resources :credits, only: %i[index new create edit update destroy] do
    collection do
      get :search
    end
  end

  resources :press_kits, only: %i[index show new create edit] do
    member do
      get :preview
    end
    resource :header, only: %i[edit update]
    resources :sections, only: %i[create edit update destroy] do
      member do
        get :heading
      end
      resources :library_images, only: %i[index create destroy], controller: "section_library_images"
      resources :quotes, only: %i[create edit update destroy] do
        resource :image, only: :destroy, controller: "quote_images"
      end
      resource :quote_order, only: :update, controller: "quote_orders"
      resources :facts, only: %i[new create edit update destroy]
      resource :fact_order, only: :update, controller: "fact_orders"
      resources :credits, only: %i[new create edit update destroy], controller: "section_credits"
      resource :credit_lines, only: :update, controller: "section_credit_lines"
      resource :credit_order, only: :update, controller: "credit_orders"
      resources :videos, only: %i[new create edit update destroy]
      resources :locations, only: %i[new create edit update destroy]
    end
    resource :order, only: :update, controller: "orders"
  end

  root to: "press_kits#index"
end
# rubocop:enable Metrics/BlockLength
