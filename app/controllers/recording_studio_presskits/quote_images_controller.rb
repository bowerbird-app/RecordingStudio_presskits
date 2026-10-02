# frozen_string_literal: true

module RecordingStudioPresskits
  class QuoteImagesController < ApplicationController
    before_action :require_root!
    before_action :set_press_kit
    before_action :set_section

    def destroy
      authorize_recording!(@press_kit_recording, role: :edit)
      return if performed?
      return head :not_found unless quote_recording && attachment_recording

      redirect_after_remove(remove_attachment)
    end

    private

    attr_reader :section_recording

    def remove_attachment
      RecordingStudioAttachable::Services::RemoveAttachment.call(
        attachment_recording: attachment_recording,
        actor: presskits_actor
      )
    end

    def redirect_after_remove(result)
      if result.success?
        redirect_to quote_edit_path, notice: "Image removed."
      else
        redirect_to quote_edit_path, alert: result.error.presence || "Could not remove that image."
      end
    end

    def quote_recording
      return @quote_recording if defined?(@quote_recording)

      @quote_recording = find_quote
    end

    def attachment_recording
      return @attachment_recording if defined?(@attachment_recording)

      @attachment_recording = find_attachment
    end

    def find_quote
      section_recording.child_recordings.where(
        trashed_at: nil,
        recordable_type: "RecordingStudioPresskits::Quote"
      ).find_by(id: params[:quote_id])
    end

    def find_attachment
      return unless quote_recording

      quote_recording.child_recordings.where(attachment_scope).first
    end

    def attachment_scope
      { trashed_at: nil, recordable_type: "RecordingStudioAttachable::Attachment" }
    end

    def quote_edit_path
      edit_press_kit_section_quote_path(@press_kit_recording, section_recording, quote_recording)
    end

    def set_section
      return if performed?

      @section_recording = KitQuery.live_child(@press_kit_recording, params[:section_id])
      return if @section_recording&.recordable.is_a?(QuoteSection)

      head :not_found
    end

    def set_press_kit
      @press_kit_recording = load_press_kit(params[:press_kit_id])
      return if @press_kit_recording.present?

      head :not_found
    end
  end
end
