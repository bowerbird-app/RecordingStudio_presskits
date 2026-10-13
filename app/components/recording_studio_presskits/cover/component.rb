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

      def initialize(recording: nil, title: nil, description: nil, subtitle: nil, brand_color: nil, # rubocop:disable Metrics/ParameterLists, Metrics/MethodLength
                     font_family: nil, size: :card, href: nil, id: nil, heading: :h2, add_to_list: true,
                     show_image: true)
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
        @title_tag = %i[h1 h2].include?(heading&.to_sym) ? heading.to_sym : :h2
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
        Cover::Contrast.text_on(brand_color)
      end

      def font_style
        css = BrandStyle.font_css_for(font_family)
        return if css.blank?

        "font-family: #{css};"
      end

      def pill_style
        "#{pill_declarations.join('; ')};"
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

      def pill_declarations
        [
          "background-color: #{brand_color}",
          "color: #{brand_text_color}",
          "--badge-primary-background-color: #{brand_color}",
          "--badge-primary-text-color: #{brand_text_color}",
          "--badge-primary-border-color: transparent"
        ]
      end

      def kit_branding
        @kit_branding ||= KitBranding.for(@recording)
      end

      def recordable
        @recording&.recordable
      end
    end
  end
end
