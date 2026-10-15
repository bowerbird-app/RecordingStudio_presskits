# frozen_string_literal: true

module RecordingStudioPresskits
  class ApplicationController < ActionController::Base
    include RecordingStudio::UsesDefaultLayout
    include Devise::Controllers::Helpers if defined?(Devise::Controllers::Helpers)
    if defined?(RecordingStudio::RootSwitchable::ControllerSupport)
      include RecordingStudio::RootSwitchable::ControllerSupport
    end

    protect_from_forgery with: :exception
    layout "recording_studio/default_layout"

    helper ::RecordingStudio::LayoutHelper if defined?(::RecordingStudio::LayoutHelper)
    helper ::RecordingStudioAccessible::AvatarsHelper if defined?(::RecordingStudioAccessible::AvatarsHelper)
    helper ::RecordingStudioPublishable::Engine.helpers if defined?(::RecordingStudioPublishable::Engine)
    helper ::RecordingStudioDownloadable::Engine.helpers if defined?(::RecordingStudioDownloadable::Engine)
    helper ::RecordingStudioEmbargo::ApplicationHelper if defined?(::RecordingStudioEmbargo::ApplicationHelper)
    helper ::RecordingStudioEmbargo::Engine.helpers if defined?(::RecordingStudioEmbargo::Engine)
    helper RecordingStudioCompany::DisplayHelper if defined?(RecordingStudioCompany::DisplayHelper)
    helper RecordingStudioAttachable::ApplicationHelper if defined?(RecordingStudioAttachable::ApplicationHelper)
    helper RecordingStudioLocation::LocationsHelper if defined?(RecordingStudioLocation::LocationsHelper)
    helper RecordingStudioLocation::Engine.helpers if defined?(RecordingStudioLocation::Engine)
    helper FlatPack::ModalHelper if defined?(FlatPack::ModalHelper)
    include KitEditorHelper

    # After protect_from_forgery so :verify_authenticity_token runs before auth filters.
    include RecordingStudioAccessible::ControllerAuth

    recording_studio_auth(
      config: -> { RecordingStudioPresskits.configuration },
      prefix: :presskits
    )

    helper_method :presskits_editor_dialog?
    helper_method :presskits_editor_modal_id
    helper_method :presskits_editor_screen_id
    helper_method :presskits_editor_open_data
    helper_method :presskits_editor_nav
    helper_method :presskits_editor_save_data
    helper_method :from_kit_editor?
    helper_method :editor_picker_items
    helper_method :editable_section_for
    helper_method :sections_order_for

    private

    def load_press_kit(id)
      KitQuery.for_root(current_presskits_root).find_by(id: id)
    end

    def respond_with_preview_or_redirect(html_redirect:, notice:)
      respond_to do |format|
        format.turbo_stream do
          if from_kit_editor?
            render template: "recording_studio_presskits/editor/preview_section"
          else
            redirect_to html_redirect, notice: notice
          end
        end
        format.html { redirect_to html_redirect, notice: notice }
      end
    end
  end
end
