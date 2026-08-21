# frozen_string_literal: true

module RecordingStudioPresskits
  module Admin
    PressKitsListWidget = RecordingStudioAdmin::Widget.new("widgets.press_kits.list") do
      type :list
      title "Press kits"
      info "Newest kits first. Trashed kits stay off this list."
      blast_radius :site
      hide_metric
      hide_change
      hide_period
      list_options divider: true, hover: true, compact_preview: :text_summary
      items do |_context|
        RecordingStudioPresskits::KitQuery.live_kits
                                          .reorder(created_at: :desc)
                                          .limit(25)
                                          .filter_map do |recording|
                                            title = recording.recordable&.try(:title)
                                            next if title.blank?

                                            {
                                              icon: :folder,
                                              text: title
                                            }
                                          end
      end
    end
  end
end
