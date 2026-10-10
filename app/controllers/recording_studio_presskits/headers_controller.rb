# frozen_string_literal: true

module RecordingStudioPresskits
  class HeadersController < ApplicationController
    before_action :require_root!
    before_action :set_press_kit

    def edit
      authorize_recording!(@press_kit_recording, role: :edit)
      return if performed?

      assign_header_fields
    end

    def update
      authorize_recording!(@press_kit_recording, role: :edit)
      return if performed?

      save_header
    end

    private

    def set_press_kit
      @press_kit_recording = load_press_kit(params[:press_kit_id])
      return if @press_kit_recording.present?

      head :not_found
    end

    def press_kit_params
      params.fetch(:press_kit, {}).permit(
        :title, :description, :cover_style, :cover_color, :cover_text_color, :cover_text_swatch
      )
    end

    def location_params
      params.fetch(:location, {}).permit(*RecordingStudio::Location.permitted_attributes)
    end

    def save_header
      fields = HeaderAttributes.from(press_kit_params)
      return render_missing_title(fields) if fields[:title].blank?

      revise_header(fields)
      save_kit_location
      respond_to_header_save
    rescue ActiveRecord::RecordInvalid => e
      render_invalid_header(fields, e)
    end

    def respond_to_header_save
      notice = "Saved. That's what people see first."
      path = edit_press_kit_header_path(@press_kit_recording)
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

    def revise_header(fields)
      current_presskits_root.revise(@press_kit_recording) do |press_kit|
        press_kit.assign_attributes(fields)
      end
    end

    def save_kit_location
      return unless params.key?(:location)

      KitLocation.save!(
        parent_recording: @press_kit_recording,
        attributes: location_params.to_h.symbolize_keys,
        actor: presskits_actor,
        reviser: current_presskits_root
      )
    end

    def kit_location_recording
      KitLocation.recording_for(@press_kit_recording)
    end

    def assign_header_fields(overrides = {})
      recordable = @press_kit_recording.recordable
      @header_title = field_or_saved(overrides, :title, recordable.title)
      @header_description = field_or_saved(overrides, :description, recordable.description)
      @header_cover_style = field_or_saved(overrides, :cover_style, recordable.cover_style)
      @header_cover_color = field_or_saved(overrides, :cover_color, recordable.cover_color)
      @header_cover_text_color = field_or_saved(overrides, :cover_text_color, recordable.cover_text_color)
      @header_location = kit_location_recording&.recordable || RecordingStudio::Location::Location.new
    end

    def field_or_saved(overrides, key, saved)
      overrides.key?(key) ? overrides[key] : saved
    end

    def render_missing_title(fields)
      assign_header_fields(fields)
      flash.now[:alert] = "Give it a name so you can find it later."
      render :edit, status: :unprocessable_entity
    end

    def render_invalid_header(fields, error)
      assign_header_fields(fields)
      flash.now[:alert] = invalid_header_alert(error)
      render :edit, status: :unprocessable_entity
    end

    def invalid_header_alert(error)
      messages = error.record.errors
      return "Pick a colour we can actually paint." if messages[:cover_color].any?
      return "Pick a text colour we can actually paint." if messages[:cover_text_color].any?
      return "That cover style is not ready yet." if messages[:cover_style].any?
      return "Check the place. Something there is off." if error.record.is_a?(RecordingStudio::Location::Location)

      "Keep that description short. 280 characters is the limit."
    end
  end
end
