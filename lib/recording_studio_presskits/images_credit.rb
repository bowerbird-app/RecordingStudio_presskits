# frozen_string_literal: true

module RecordingStudioPresskits
  module ImagesCredit
    TEMPLATE = "High-resolution photography, free for editorial use. Please credit “%<brand>s”."

    def self.line_for(brand)
      name = brand.to_s.strip.presence || "the maker"
      format(TEMPLATE, brand: name)
    end
  end
end
