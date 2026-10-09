# frozen_string_literal: true

module RecordingStudioPresskits
  module CoverSettings
    def cover_palette
      configuration.cover_palette
    end

    def any_cover_color?
      configuration.any_cover_color?
    end

    def default_cover_color
      cover_palette.default_color
    end

    def cover_text_palette
      configuration.cover_text_palette
    end

    def any_cover_text_color?
      configuration.any_cover_text_color?
    end

    def cover_text_auto?
      configuration.cover_text_auto?
    end
  end
end
