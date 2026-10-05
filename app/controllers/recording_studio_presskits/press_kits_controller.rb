# frozen_string_literal: true

module RecordingStudioPresskits
  class PressKitsController < ApplicationController
    before_action :require_root!
    before_action :set_press_kit, only: %i[show preview edit update]

    def index
      authorize_recording!(current_presskits_root, role: :view)
      return if performed?

      @press_kit_recordings = KitQuery.for_root(current_presskits_root)
      @view = table_view? ? "table" : "cards"
    end

    def show
      authorize_recording!(@press_kit_recording, role: :edit)
      return if performed?

      redirect_to edit_press_kit_path(@press_kit_recording)
    end

    def preview
      authorize_recording!(@press_kit_recording, role: :view)
      return if performed?

      @section_recordings = KitQuery.live_children(@press_kit_recording)
    end

    def edit
      authorize_recording!(@press_kit_recording, role: :edit)
      return if performed?

      @section_recordings = KitQuery.live_children(@press_kit_recording)
      @picker_types = RecordingStudioPresskits.picker_types
      assign_header_fields
    end

    def update
      authorize_recording!(@press_kit_recording, role: :edit)
      return if performed?

      save_header
    end

    def new
      authorize_recording!(current_presskits_root, role: :edit)
      return if performed?

      @press_kit = PressKit.new
    end

    def create
      authorize_recording!(current_presskits_root, role: :edit)
      return if performed?

      title = press_kit_params[:title].to_s.strip
      return render_missing_title if title.blank?

      recording = current_presskits_root.record(PressKit) { |press_kit| press_kit.title = title }
      redirect_to edit_press_kit_path(recording), notice: "Press kit is ready. Add a section when you are."
    rescue ActiveRecord::RecordInvalid
      render_missing_title(title)
    end

    private

    def set_press_kit
      @press_kit_recording = load_press_kit(params[:id])
      return if @press_kit_recording.present?

      head :not_found
    end

    def table_view?
      params[:view].to_s == "table"
    end

    def press_kit_params
      params.fetch(:press_kit, {}).permit(:title, :description)
    end

    def save_header
      title, description = header_fields
      return render_missing_edit_title(title, description) if title.blank?

      revise_header(title, description)
      redirect_to edit_press_kit_path(@press_kit_recording), notice: "Saved. That's what people see first."
    rescue ActiveRecord::RecordInvalid
      render_invalid_header(title, description)
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

    def render_missing_title(title = nil)
      @press_kit = PressKit.new(title: title)
      flash.now[:alert] = "Give it a name so you can find it later."
      render :new, status: :unprocessable_entity
    end

    def render_missing_edit_title(title = nil, description = nil)
      prepare_header_edit(title, description)
      flash.now[:alert] = "Give it a name so you can find it later."
      render :edit, status: :unprocessable_entity
    end

    def render_invalid_header(title, description)
      prepare_header_edit(title, description)
      flash.now[:alert] = "Keep that description short. 280 characters is the limit."
      render :edit, status: :unprocessable_entity
    end

    def prepare_header_edit(title, description)
      @section_recordings = KitQuery.live_children(@press_kit_recording)
      @picker_types = RecordingStudioPresskits.picker_types
      assign_header_fields(title: title, description: description)
    end
  end
end
