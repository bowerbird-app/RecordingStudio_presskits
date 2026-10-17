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
  mount RecordingStudioPublishable::Engine, at: "/"
  mount RecordingStudioPresskits::Engine, at: "/recording_studio_presskits"
  mount RecordingStudioApi::Engine, at: "/recording_studio_api"
  get "APIdocs", to: "recording_studio_api/scalar_docs#redirect_to_default", defaults: { api_key: "public", engine_mount_path: "/recording_studio_api" }, as: :api_docs_root
  get "APIdocs/:version/openapi.json", to: "recording_studio_api/scalar_docs#openapi", defaults: { api_key: "public", engine_mount_path: "/recording_studio_api" }, as: :api_docs_openapi
  get "APIdocs/:version/fullscreen", to: "recording_studio_api/scalar_docs#fullscreen", defaults: { api_key: "public", engine_mount_path: "/recording_studio_api" }, as: :api_docs_fullscreen
  get "APIdocs/:version", to: "recording_studio_api/scalar_docs#show", defaults: { api_key: "public", engine_mount_path: "/recording_studio_api" }, as: :api_docs
  mount RecordingStudioAccessible::Engine, at: "/admin/access"
  mount RecordingStudioAttachable::Engine, at: "/recording_studio_attachable"
  mount RecordingStudioDownloadable::Engine, at: "/recording_studio_downloadable"
  mount RecordingStudioEmbargo::Engine, at: "/recording_studio_embargo"
  mount RecordingStudioCompany::Engine, at: "/recording_studio_company"
  mount RecordingStudioLocation::Engine, at: "/recording_studio_location"
  recording_studio_admin_for :admin, at: "/admin", root_section: :press_kits

  get "up" => "rails/health#show", as: :rails_health_check
  get "/kit-embeds/:id", to: "kit_embeds#show", as: :kit_embed

  root to: redirect("/recording_studio_presskits")

  # Lists README: mount after host routes so / stays the host home.
  # Screens are /lists, /lists/new, and /lists/:id.
  mount RecordingStudioLists::Engine, at: "/"
end
