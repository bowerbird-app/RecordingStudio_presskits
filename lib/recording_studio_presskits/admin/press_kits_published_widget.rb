# frozen_string_literal: true

module RecordingStudioPresskits
  module Admin
    PressKitsPublishedWidget = RecordingStudioAdmin::Widget.new("widgets.press_kits.published") do
      type :list
      title "Live kits"
      info "Out in the world. Search can find these."
      blast_radius :site
      hide_metric
      hide_change
      hide_period
      list_options divider: true, hover: true, compact_preview: :text_summary
      items do |_context|
        RecordingStudioPresskits::KitQuery.published_kits
                                          .limit(25)
                                          .filter_map do |recording|
                                            title = recording.recordable&.try(:title)
                                            next if title.blank?

                                            {
                                              icon: :globe,
                                              text: title
                                            }
                                          end
      end
    end
  end
end
