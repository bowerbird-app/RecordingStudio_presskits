# frozen_string_literal: true

module RecordingStudioPresskits
  # Shown in place of the package poller while KitDownloadGate is open.
  # Downloadable initializes it with recording:, actor:, and action:.
  class DownloadGateComponent < ViewComponent::Base
    def initialize(recording:, actor:, action:)
      super()
      @recording = recording
      @actor = actor
      @action = action
    end

    def call
      helpers.tag.div(**wrapper_attributes) do
        helpers.safe_join([download_button, modal])
      end
    end

    private

    def wrapper_attributes
      {
        data: {
          controller: "recording-studio-presskits--download-gate",
          action: "recording-studio-downloadable:download-gate@window->recording-studio-presskits--download-gate#hold",
          "recording-studio-presskits--download-gate-modal-id-value": KitDownloadGate.modal_id(@recording),
          "recording-studio-presskits--download-gate-recording-id-value": @recording.id
        }
      }
    end

    def download_button
      options = {
        text: button_text,
        style: button_style,
        size: button_size,
        icon: "arrow-down-tray",
        type: "button",
        data: button_data
      }
      options[:class] = Cover::DefaultActionsComponent::BUTTON_WIDTH if kit_action?
      helpers.render(FlatPack::Button::Component.new(**options))
    end

    def modal
      helpers.render(modal_component) do |modal|
        modal.body { modal_body }
      end
    end

    def modal_component
      FlatPack::Modal::Component.new(
        id: KitDownloadGate.modal_id(@recording),
        size: :md
      )
    end

    def modal_body
      helpers.render(FlatPack::Card::Body::Component.new(padding: :lg)) do
        helpers.render(
          partial: "recording_studio_presskits/download_gates/frame",
          locals: { recording: @recording }
        )
      end
    end

    def kit_action?
      @action.to_sym == KitDownload::ACTION
    end

    def button_text
      suffix = kit_action? ? "download.button" : "images.download_all"
      I18n.t("recording_studio_presskits.#{suffix}")
    end

    def button_style
      kit_action? ? :primary : :default
    end

    def button_size
      kit_action? ? :lg : :md
    end

    def button_data
      data = { "modal-id": KitDownloadGate.modal_id(@recording) }
      data[kit_action? ? :cover_download : :images_download] = true
      data
    end
  end
end
