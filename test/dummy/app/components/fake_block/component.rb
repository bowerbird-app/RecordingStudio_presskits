class FakeBlock::Component < ViewComponent::Base
  def initialize(recording:)
    @recording = recording
    @fake_block = recording.recordable
  end
end
