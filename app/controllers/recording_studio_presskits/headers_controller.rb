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
      params.fetch(:press_kit, {}).permit(:title, :description)
    end

    def save_header
      title, description = header_fields
      return render_missing_title(title, description) if title.blank?

      revise_header(title, description)
      respond_to_header_save
    rescue ActiveRecord::RecordInvalid
      render_invalid_header(title, description)
    end

    def respond_to_header_save
      notice = "Saved. That's what people see first."
      respond_to do |format|
        format.turbo_stream do
          if from_kit_editor?
            render :update
          else
            redirect_to after_header_save_path, notice: notice
          end
        end
        format.html { redirect_to after_header_save_path, notice: notice }
      end
    end

    def after_header_save_path
      edit_press_kit_header_path(@press_kit_recording)
    end

    def from_kit_editor?
      super || request.referer.to_s.include?("/press_kits/#{@press_kit_recording.id}/edit")
    end

    def header_fields
      submitted = press_kit_params
      [submitted[:title].to_s.strip, submitted[:description].to_s.strip.presence]
    end

    def revise_header(title, description)
      current_presskits_root.revise(@press_kit_recording) do |press_kit|
        press_kit.assign_attributes(title: title, description: description)
      end
    end

    def assign_header_fields(title: :saved, description: :saved)
      recordable = @press_kit_recording.recordable
      @header_title = title == :saved ? recordable.title : title
      @header_description = description == :saved ? recordable.description : description
    end

    def render_missing_title(title, description)
      assign_header_fields(title: title, description: description)
      flash.now[:alert] = "Give it a name so you can find it later."
      render :edit, status: :unprocessable_entity
    end

    def render_invalid_header(title, description)
      assign_header_fields(title: title, description: description)
      flash.now[:alert] = "Keep that description short. 280 characters is the limit."
      render :edit, status: :unprocessable_entity
    end
  end
end
