# frozen_string_literal: true

module RecordingStudioPresskits
  class PressKitsController < ApplicationController
    INDEX_FILTER_KEYS = %i[published publish_from publish_to].freeze

    before_action :require_root!
    before_action :set_press_kit, only: %i[show preview edit]

    def index
      authorize_recording!(current_presskits_root, role: :view)
      return if performed?

      @index_filters = index_filter_params
      kits = KitQuery.for_root(current_presskits_root)
      @press_kit_recordings = PublishedKits.filter_index(kits, **index_filter_values)
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

      @section_recordings = KitQuery.sections_for(@press_kit_recording)
    end

    def edit
      authorize_recording!(@press_kit_recording, role: :edit)
      return if performed?

      @section_recordings = KitQuery.sections_for(@press_kit_recording)
      @picker_types = RecordingStudioPresskits.picker_types
      @highlight_id = params[:highlight]
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

    def index_filter_params
      params.permit(*INDEX_FILTER_KEYS).to_h.symbolize_keys.compact_blank
    end

    def index_filter_values
      {
        published: ActiveModel::Type::Boolean.new.cast(@index_filters[:published]) || false,
        publish_from: index_time(@index_filters[:publish_from]),
        publish_to: index_time(@index_filters[:publish_to])
      }
    end

    # ISO 8601 date (start of that day in Time.zone) or timestamp; invalid values are ignored.
    def index_time(value)
      return if value.blank?

      value.match?(/\A\d{4}-\d{2}-\d{2}\z/) ? Date.iso8601(value).in_time_zone : Time.iso8601(value)
    rescue ArgumentError
      nil
    end

    def table_view?
      params[:view].to_s == "table"
    end

    def press_kit_params
      params.fetch(:press_kit, {}).permit(:title)
    end

    def render_missing_title(title = nil)
      @press_kit = PressKit.new(title: title)
      flash.now[:alert] = "Give it a name so you can find it later."
      render :new, status: :unprocessable_entity
    end
  end
end
