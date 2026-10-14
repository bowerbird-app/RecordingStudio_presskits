# frozen_string_literal: true

module RecordingStudioPresskits
  class Images
    class Component < ViewComponent::Base
      PAGE_SIZE = 12
      COLUMNS = { base: 1, md: 2, lg: 4 }.freeze

      def initialize(recording:)
        super()
        @recording = recording
      end

      def render?
        DirectImages.list(@recording).any?
      end

      def tiles
        @tiles ||= DirectImages.list(@recording).filter_map { |item| tile_for(item) }
      end

      def visible_tiles
        expanded? ? tiles : tiles.first(PAGE_SIZE)
      end

      def show_more?
        !expanded? && tiles.size > PAGE_SIZE
      end

      def show_more_button
        FlatPack::Button::Component.new(
          text: I18n.t("recording_studio_presskits.images.show_more", count: tiles.size),
          style: :default,
          href: more_path,
          data: { turbo_frame: frame_id }
        )
      end

      def frame_id
        "presskits-images-#{@recording.id}"
      end

      def columns
        COLUMNS
      end

      private

      def expanded?
        helpers.params[:images].to_s == @recording.id.to_s
      end

      def tile_for(item)
        url = DirectImages.url_for(item, helpers: helpers)
        facts = RecordingStudioPresskits::ImageFacts.new(item.recordable)
        return if url.blank? || facts.width.nil? || facts.height.nil?

        image_tile(item, url, facts)
      end

      def image_tile(item, url, facts)
        {
          src: url,
          alt: DirectImages.alt_for(item),
          width: facts.width,
          height: facts.height,
          name: facts.name,
          meta: facts.meta
        }
      end

      def more_path
        query = helpers.request.query_parameters.merge("images" => @recording.id)
        "#{helpers.request.path}?#{query.to_query}"
      end
    end
  end
end
