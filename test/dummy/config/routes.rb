Rails.application.routes.draw do
  devise_for :users

  # RecordingStudio engine is data/API-focused and has no browser root route.
  # Keep legacy links working by redirecting the base path to the press kit slice.
  get "/recording_studio", to: redirect("/recording_studio_presskits"), as: nil
  mount RecordingStudio::Engine, at: "/recording_studio"
  mount RecordingStudioRootSwitchable::Engine, at: "/recording_studio_root_switchable"
  mount RecordingStudioOrderable::Engine, at: "/recording_studio_orderable"
  mount RecordingStudioTrashable::Engine, at: "/recording_studio_trashable"
  mount RecordingStudioDuplicatable::Engine, at: "/recording_studio_duplicatable"
  mount RecordingStudioPresskits::Engine, at: "/recording_studio_presskits"
  mount RecordingStudioAccessible::Engine, at: "/admin/access"
  recording_studio_admin_for :admin, at: "/admin", root_section: :press_kits

  get "up" => "rails/health#show", as: :rails_health_check

  root to: redirect("/recording_studio_presskits")
end
