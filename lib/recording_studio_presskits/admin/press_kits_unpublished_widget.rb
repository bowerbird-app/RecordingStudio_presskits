# frozen_string_literal: true

module RecordingStudioPresskits
  module Admin
    PressKitsUnpublishedWidget = RecordingStudioAdmin::Widget.new("widgets.press_kits.unpublished") do
      type :list
      title "Not live yet"
      info "Still in the drawer. The public cannot see these."
      blast_radius :site
      hide_metric
      hide_change
      hide_period
      list_options divider: true, hover: true, compact_preview: :text_summary
      items do |_context|
        RecordingStudioPresskits::KitQuery.unpublished_kits
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
