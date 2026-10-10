# frozen_string_literal: true

module RecordingStudioPresskits
  class KitDownloadsController < ApplicationController
    before_action :require_root!
    before_action :set_press_kit

    def edit
      authorize_recording!(@press_kit_recording, role: :edit)
      return if performed?

      assign_download_fields
    end

    def update
      authorize_recording!(@press_kit_recording, role: :edit)
      return if performed?

      save_downloads
    rescue RecordingStudioAccessible::AudienceUnauthorized,
           RecordingStudioAccessible::AudienceNotAllowed,
           RecordingStudioAccessible::AudienceInvalid
      render_invalid_downloads
    end

    private

    def set_press_kit
      @press_kit_recording = load_press_kit(params[:press_kit_id])
      return if @press_kit_recording.present?

      head :not_found
    end

    def download_params
      params.fetch(:downloads, {}).permit(:audience)
    end

    def save_downloads
      KitDownload.set_audience!(
        recording: @press_kit_recording,
        audience: download_params[:audience],
        actor: presskits_actor
      )
      respond_to_downloads_save
    end

    def respond_to_downloads_save
      notice = I18n.t("recording_studio_presskits.downloads.saved")
      path = edit_press_kit_downloads_path(@press_kit_recording)
      respond_to do |format|
        format.turbo_stream do
          from_kit_editor? ? render_saved_form : redirect_to(path, notice: notice)
        end
        format.html { redirect_to path, notice: notice }
      end
    end

    def from_kit_editor?
      super || request.referer.to_s.include?("/press_kits/#{@press_kit_recording.id}/edit")
    end

    def assign_download_fields
      @download_audience = KitDownload.effective_audience(@press_kit_recording)
      @download_options = KitDownload.audience_options_for(@press_kit_recording)
      @download_constrained = KitDownload.constrained?(@press_kit_recording)
    end

    def render_saved_form
      assign_download_fields
      render :update
    end

    def render_invalid_downloads
      assign_download_fields
      flash.now[:alert] = I18n.t("recording_studio_presskits.downloads.invalid")
      render :edit, status: :unprocessable_entity
    end
  end
end
