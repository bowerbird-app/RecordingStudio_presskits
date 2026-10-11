# frozen_string_literal: true

module RecordingStudioPresskits
  class VisibilitiesController < ApplicationController
    before_action :require_root!
    before_action :set_press_kit

    def edit
      authorize_recording!(@press_kit_recording, role: :edit)
      return if performed?

      assign_visibility_fields
    end

    def update
      authorize_recording!(@press_kit_recording, role: :edit)
      return if performed?

      save_visibility
    rescue RecordingStudioAccessible::AudienceUnauthorized,
           RecordingStudioAccessible::AudienceNotAllowed,
           RecordingStudioAccessible::AudienceInvalid
      render_invalid_visibility
    end

    private

    def set_press_kit
      @press_kit_recording = load_press_kit(params[:press_kit_id])
      return if @press_kit_recording.present?

      head :not_found
    end

    def visibility_params
      params.fetch(:visibility, {}).permit(:audience, :visibility_fallback)
    end

    def save_visibility
      persist_audience
      persist_fallback
      respond_to_visibility_save
    end

    def persist_audience
      Visibility.set_audience!(
        recording: @press_kit_recording,
        audience: visibility_params[:audience],
        actor: presskits_actor
      )
    end

    def persist_fallback
      KitSettings.save_fallback!(
        recording: @press_kit_recording,
        fallback: visibility_params[:visibility_fallback].presence ||
                  KitSettings.fallback_for(@press_kit_recording),
        actor: presskits_actor
      )
    end

    def respond_to_visibility_save
      notice = I18n.t("recording_studio_presskits.visibility.saved")
      path = edit_press_kit_visibility_path(@press_kit_recording)
      respond_to do |format|
        format.turbo_stream do
          from_kit_editor? ? render(:update) : redirect_to(path, notice: notice)
        end
        format.html { redirect_to path, notice: notice }
      end
    end

    def from_kit_editor?
      super || request.referer.to_s.include?("/press_kits/#{@press_kit_recording.id}/edit")
    end

    def assign_visibility_fields
      @visibility_audience = Visibility.effective_audience(@press_kit_recording)
      @visibility_options = Visibility.audience_options_for(@press_kit_recording)
      @visibility_fallback = KitSettings.fallback_for(@press_kit_recording)
      @visibility_constrained = @visibility_options.none? { |option| option[:audience] == :public }
    end

    def render_invalid_visibility
      assign_visibility_fields
      flash.now[:alert] = I18n.t("recording_studio_presskits.visibility.invalid")
      render :edit, status: :unprocessable_entity
    end
  end
end
