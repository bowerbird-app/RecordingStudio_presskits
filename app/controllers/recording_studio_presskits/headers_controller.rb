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
        :title, :subtitle, :description, :brand_color, :font_family, :text_color,
        :corner_style, :brand_source, :release_date
      )
    end

    def location_params
      params.fetch(:location, {}).permit(*RecordingStudio::Location.permitted_attributes)
    end

    def save_header
      fields = HeaderAttributes.from(press_kit_params)
      return render_missing_title(fields) if missing_title?(fields)

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
        press_kit.assign_attributes(
          fields.slice(:title, :subtitle, :description, :brand_color, :font_family, :text_color,
                       :corner_style, :release_date)
        )
      end
      @press_kit_recording.reload
    end

    def missing_title?(fields)
      fields.key?(:title) && fields[:title].blank?
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

    def assign_header_fields(overrides = {})
      recordable = @press_kit_recording.recordable
      assign_header_brand(overrides, recordable)
      @header_release_date = field_or_saved(overrides, :release_date, recordable.release_date)
      saved = KitLocation.recording_for(@press_kit_recording)&.recordable
      @header_location = saved || RecordingStudio::Location::Location.new
    end

    def assign_header_brand(overrides, recordable)
      @header_brand_color = field_or_saved(overrides, :brand_color, recordable.brand_color)
      @header_font_family = field_or_saved(overrides, :font_family, recordable.font_family)
      @header_text_color = field_or_saved(overrides, :text_color, recordable.text_color)
      @header_corner_style = field_or_saved(overrides, :corner_style, recordable.corner_style)
      @header_brand_source = field_or_saved(overrides, :brand_source, HeaderAttributes.stored_source(recordable))
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
      flash.now[:alert] = HeaderAttributes.alert_for(error)
      render :edit, status: :unprocessable_entity
    end
  end
end
