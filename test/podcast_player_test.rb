# frozen_string_literal: true

require "test_helper"
require "open3"

class PodcastPlayerTest < Minitest::Test
  def test_the_player_iframe_is_mounted_only_while_the_modal_is_open
    script = File.expand_path("podcast_player.test.mjs", __dir__)
    output, status = Open3.capture2e("node", "--test", script)

    assert_predicate status, :success?, output
  end
end
