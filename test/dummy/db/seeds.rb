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

find_or_record_named_child = lambda do |type, title, root_recording, parent_recording, description: nil|
  existing = RecordingStudio::Recording.recording_studio_trashable_active
                                       .where(root_recording: root_recording, parent_recording: parent_recording,
                                              recordable_type: type.name)
                                       .find { |recording| recording.recordable.title == title }
  return existing if existing

  parent_recording.record(type, parent_recording: parent_recording) do |recordable|
    recordable.title = title
    recordable.description = description if description.present?
  end
end

bootstrap_owner_access = lambda do |recording, actor|
  current_role = RecordingStudioAccessible.role_for(actor: actor, recording: recording)
  next if current_role == :admin

  result = RecordingStudioAccessible.bootstrap_owner_access!(
    recording: recording,
    actor: actor
  )

  raise result.error if result.failure?
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
admin_root = AdminRoot.find_or_create_by!(name: "Admin")

previous_actor = Current.actor
Current.actor = user

begin
  root_recording = RecordingStudio.root_recording_for(workspace)
  accessible_root_recording = RecordingStudio.root_recording_for(accessible_workspace)
  private_root_recording = RecordingStudio.root_recording_for(private_workspace)
  admin_root_recording = RecordingStudio.root_recording_for(admin_root)

  folder_recording = find_or_record_child.call(folder, root_recording, root_recording)

  find_or_record_child.call(page, root_recording, folder_recording)

  press_kit_recording = find_or_record_named_child.call(
    RecordingStudioPresskits::PressKit,
    "Spring launch",
    root_recording,
    root_recording,
    description: "Doors at noon. The one-sheet is inside."
  )
  if press_kit_recording.recordable.cover_color.blank?
    root_recording.revise(press_kit_recording) do |press_kit|
      press_kit.cover_style = "color"
      press_kit.cover_color = "#7C3AED"
    end
    press_kit_recording.reload
  end

  unpublished_kit_recording = RecordingStudio::Recording.recording_studio_trashable_active
                                                        .where(root_recording: root_recording,
                                                               parent_recording: root_recording,
                                                               recordable_type: "RecordingStudioPresskits::PressKit")
                                                        .find { |recording| recording.recordable.title == "Autumn recap" }
  if unpublished_kit_recording.nil?
    unpublished_kit_recording = root_recording.record(RecordingStudioPresskits::PressKit) do |press_kit|
      press_kit.title = "Autumn recap"
      press_kit.description = "What we shipped, on one page."
      press_kit.cover_style = "color"
      press_kit.cover_color = "#D97706"
    end
  else
    root_recording.revise(unpublished_kit_recording) do |press_kit|
      press_kit.cover_style = "color" if press_kit.cover_color.blank?
      press_kit.cover_color = "#D97706" if press_kit.cover_color.blank?
    end
    unpublished_kit_recording.reload
  end

  trash_named_child = lambda do |parent_recording, type, title|
    existing = RecordingStudio::Recording.recording_studio_trashable_active
                                         .where(root_recording: root_recording,
                                                parent_recording: parent_recording,
                                                recordable_type: type.name)
                                         .find { |recording| recording.recordable.title == title }
    return unless existing&.respond_to?(:recording_studio_trashable_trash!)

    existing.recording_studio_trashable_trash!(actor: user)
  end

  %w[Hero Quotes].each do |title|
    trash_named_child.call(press_kit_recording, RecordingStudioPresskits::KitSection, title)
  end
  trash_named_child.call(unpublished_kit_recording, RecordingStudioPresskits::KitSection, "Notes")

  publish_kit = lambda do |kit_recording, slug:, status:|
    result = RecordingStudioPublishable::Services::Publishables::Update.call(
      parent_recording: kit_recording,
      actor: user,
      attributes: {
        slug: slug,
        status: status,
        meta_robots: "index,follow"
      }
    )
    raise result.error if result.failure?

    result.value
  end

  publish_kit.call(press_kit_recording, slug: "spring-launch", status: "published")
  publish_kit.call(unpublished_kit_recording, slug: "autumn-recap", status: "draft")

  find_or_record_credit = lambda do |root_recording, name, usual_role, url|
    existing = RecordingStudioPresskits::Credits.active_for_root(root_recording).find do |recording|
      recording.recordable.name == name
    end
    return existing if existing

    RecordingStudioPresskits::Credits.create!(
      root_recording: root_recording,
      name: name,
      url: url,
      usual_role: usual_role,
      actor: user
    )
  end

  ensure_credits_section = lambda do |kit_recording, title, lines|
    existing = RecordingStudioPresskits::KitQuery.sections_for(kit_recording).find do |section|
      section.recordable.title == title
    end
    section = existing || RecordingStudioPresskits.create_section!(
      press_kit_recording: kit_recording,
      content_type: "RecordingStudioPresskits::CreditsSection",
      actor: user,
      title: title
    )
    content = RecordingStudioPresskits::KitQuery.section_content(section)
    lines.each do |credit_recording, role|
      already = RecordingStudioPresskits::Credits.lines_for(content).any? do |line|
        line.recordable.credit_recording_id == credit_recording.id && line.recordable.role == role
      end
      next if already

      RecordingStudioPresskits::Credits.add!(
        credits_section_recording: content,
        credit_recording: credit_recording,
        role: role,
        actor: user
      )
    end
  end

  studio_bright = find_or_record_credit.call(root_recording, "Studio Bright", "Architecture", "https://studiobright.com.au")
  flack = find_or_record_credit.call(root_recording, "Flack Studio", "Interior Design", "https://flackstudio.com.au")
  tom = find_or_record_credit.call(root_recording, "Tom Ross", "Photography", nil)
  marsha = find_or_record_credit.call(root_recording, "Marsha Golemac", "Styling", nil)
  vitra = find_or_record_credit.call(root_recording, "Vitra", "Furniture", "https://www.vitra.com")

  ensure_credits_section.call(
    press_kit_recording,
    "Project credits",
    [
      [studio_bright, "Architecture"],
      [flack, "Interior Design"],
      [tom, "Photography"],
      [marsha, "Styling"],
      [vitra, "Furniture"]
    ]
  )
  ensure_credits_section.call(unpublished_kit_recording, "Credits", [[tom, "Creative Direction"]])

  ensure_facts_section = lambda do |kit_recording, title, display_style, columns, facts|
    existing = RecordingStudioPresskits::KitQuery.sections_for(kit_recording).find do |section|
      section.recordable.title == title
    end
    section = existing || RecordingStudioPresskits.create_section!(
      press_kit_recording: kit_recording,
      content_type: "RecordingStudioPresskits::FactsSection",
      actor: user,
      title: title
    )
    content = RecordingStudioPresskits::KitQuery.section_content(section)
    if content.recordable.display_style != display_style || content.recordable.columns != columns
      root_recording.revise(content, actor: user) do |recordable|
        recordable.display_style = display_style
        recordable.columns = columns
      end
    end
    facts.each do |label, value, unit|
      already = RecordingStudioPresskits::FactsSection.active_facts(content).any? do |child|
        child.recordable.label == label && child.recordable.value == value
      end
      next if already

      content.record(RecordingStudioPresskits::Fact, parent_recording: content, actor: user) do |fact|
        fact.label = label
        fact.value = value
        fact.unit = unit
      end
    end
  end

  ensure_facts_section.call(
    press_kit_recording,
    "Company statistics",
    "cards",
    3,
    [
      ["Projects", "120", nil],
      ["Countries", "15", nil],
      ["Employees", "85", nil]
    ]
  )
  ensure_facts_section.call(
    press_kit_recording,
    "Project specifications",
    "list",
    3,
    [
      ["Floor area", "420", "m²"],
      ["Completion", "2025", nil],
      ["Project cost", "2.4 million", "AUD"]
    ]
  )

  [root_recording, accessible_root_recording, private_root_recording, admin_root_recording].each do |recording|
    bootstrap_owner_access.call(recording, user)
  end
ensure
  Current.actor = previous_actor
end

puts "Seeded: admin@admin.com / Password"
puts "Seeded: Workspace '#{workspace.name}' with root recording ##{root_recording.id}"
puts "Seeded: Workspace '#{accessible_workspace.name}' with root recording ##{accessible_root_recording.id}"
puts "Seeded: Workspace '#{private_workspace.name}' with root recording ##{private_root_recording.id}"
puts "Seeded: Admin root '#{admin_root.name}' with root recording ##{admin_root_recording.id}"
puts "Seeded: Folder '#{folder.name}' and page '#{page.title}'"
puts "Seeded: Press kit 'Spring launch' published at /published/:uuid/spring-launch"
puts "Seeded: Press kit 'Autumn recap' as unpublished"
