module ApplicationHelper
  def presskits_extra_nav
    render(
      FlatPack::Button::Component.new(
        text: "Sign out",
        style: :ghost,
        size: :md,
        href: main_app.destroy_user_session_path,
        data: { turbo_method: :delete }
      )
    )
  end
end
