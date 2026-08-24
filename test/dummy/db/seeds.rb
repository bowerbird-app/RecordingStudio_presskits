# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

find_or_record_child = lambda do |recordable, root_recording, parent_recording|
  RecordingStudio::Recording.recording_studio_trashable_active.find_by(
    root_recording: root_recording,
    parent_recording: parent_recording,
    recordable: recordable
  ) || RecordingStudio.record!(
    action: "created",
    recordable: recordable,
    root_recording: root_recording,
    parent_recording: parent_recording
  ).recording
end

find_or_record_named_child = lambda do |type, title, root_recording, parent_recording|
  existing = RecordingStudio::Recording.recording_studio_trashable_active
                                       .where(root_recording: root_recording, parent_recording: parent_recording,
                                              recordable_type: type.name)
                                       .find { |recording| recording.recordable.title == title }
  return existing if existing

  parent_recording.record(type, parent_recording: parent_recording) do |recordable|
    recordable.title = title
  end
end

# Create the admin user
user = User.find_or_create_by!(email: "admin@admin.com") do |u|
  u.password = "Password"
  u.password_confirmation = "Password"
end

# Create the workspace recordables
workspace = Workspace.find_or_create_by!(name: "Studio Workspace")
accessible_workspace = Workspace.find_or_create_by!(name: "Client Workspace")
private_workspace = Workspace.find_or_create_by!(name: "Private Workspace")
folder = Folder.find_or_create_by!(name: "Product Docs")
page = Page.find_or_create_by!(title: "Getting Started")

previous_actor = Current.actor
Current.actor = user

begin
  root_recording = RecordingStudio.root_recording_for(workspace)
  accessible_root_recording = RecordingStudio.root_recording_for(accessible_workspace)
  private_root_recording = RecordingStudio.root_recording_for(private_workspace)

  folder_recording = find_or_record_child.call(folder, root_recording, root_recording)

  find_or_record_child.call(page, root_recording, folder_recording)

  press_kit_recording = RecordingStudio::Recording.recording_studio_trashable_active.find_by(
    root_recording: root_recording,
    parent_recording: root_recording,
    recordable_type: "RecordingStudioPresskits::PressKit"
  )

  if press_kit_recording.nil?
    press_kit_recording = root_recording.record(RecordingStudioPresskits::PressKit) do |press_kit|
      press_kit.title = "Spring launch"
    end
  end

  find_or_record_named_child.call(FakeBlock, "Hero", root_recording, press_kit_recording)
  find_or_record_named_child.call(FakeBlock, "Quotes", root_recording, press_kit_recording)
ensure
  Current.actor = previous_actor
end

puts "Seeded: admin@admin.com / Password"
puts "Seeded: Workspace '#{workspace.name}' with root recording ##{root_recording.id}"
puts "Seeded: Workspace '#{accessible_workspace.name}' with root recording ##{accessible_root_recording.id}"
puts "Seeded: Workspace '#{private_workspace.name}' with root recording ##{private_root_recording.id}"
puts "Seeded: Folder '#{folder.name}' and page '#{page.title}'"
puts "Seeded: Press kit 'Spring launch' with fake blocks 'Hero' and 'Quotes'"
