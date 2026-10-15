# frozen_string_literal: true

module RecordingStudioPresskits
  module Cover
    class Component < ViewComponent::Base
      include RecordingStudioCompany::DisplayHelper if defined?(RecordingStudioCompany::DisplayHelper)
      include RecordingStudioAttachable::ApplicationHelper if defined?(RecordingStudioAttachable::ApplicationHelper)
      include Byline
      include Image
      include GridCard

      SIZES = %i[card].freeze

      # Editor chrome. Index, public, and preview cards leave both empty.
      renders_one :body_actions
      renders_one :image_actions
      # Caller-supplied card actions. An empty collection hides the row.
      renders_many :actions

      def initialize(recording: nil, title: nil, description: nil, subtitle: nil, brand_color: nil, inline_path: nil, # rubocop:disable Metrics/ParameterLists, Metrics/MethodLength
                     font_family: nil, size: :card, href: nil, id: nil, heading: :h2, add_to_list: true,
                     show_image: true, context: :header)
        super()
        @recording = recording
        @title = title
        @description = description
        @subtitle = subtitle
        @brand_color = brand_color
        @font_family = font_family
        @size = SIZES.include?(size&.to_sym) ? size.to_sym : :card
        @href = href
        @id = id
        @context = context.to_sym
        assign_inline_heading(heading, inline_path)
        @add_to_list = add_to_list
        @show_image = show_image
      end

      def title
        @title.presence || recordable&.try(:title).presence || "Press kit"
      end

      def description
        text = @description.nil? ? recordable&.try(:description) : @description
        text.to_s.strip.presence
      end

      def release_line
        date = release_date
        return if date.blank?

        I18n.t(
          "recording_studio_presskits.cover.released",
          date: I18n.l(date.to_date, format: "%-d %b %Y")
        )
      end

      def wide_line?
        release_line.present? || location_recordable.present?
      end

      def location_icon
        location_recordable&.resolved_icon.presence || "map-pin"
      end

      def subtitle
        text = @subtitle.nil? ? recordable&.try(:subtitle) : @subtitle
        text.to_s.strip.presence
      end

      def brand_color
        explicit = Cover::Hex.normalize(@brand_color)
        return explicit if explicit

        kit_branding.brand_color
      end

      def font_family
        key = BrandStyle.normalize_font(@font_family)
        return key if key.is_a?(String)

        kit_branding.font_family
      end

      def brand_text_color
        color = BrandStyle.normalize_color(kit_branding.text_color)
        color.is_a?(String) ? color : Cover::Contrast.text_on(brand_color)
      end

      def font_style
        css = BrandStyle.font_css_for(font_family)
        return if css.blank?

        "font-family: #{css};"
      end

      def card?
        @size == :card
      end

      def preview?
        false
      end

      def href
        @href.presence
      end

      def eyebrow
        I18n.t("recording_studio_presskits.cover.eyebrow")
      end

      def wrapper_id
        @id.presence
      end

      def heading_tag
        title_tag
      end

      private

      def kit_branding
        @kit_branding ||= KitBranding.for(@recording)
      end

      def recordable
        @recording&.recordable
      end

      def release_date
        recordable&.try(:release_date)
      end
    end
  end
end
