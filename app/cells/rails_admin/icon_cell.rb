module RailsAdmin
  class IconCell < BaseCell
    delegate(
      :content_tag,
      :capitalize_first_letter,
      to: :view_context
    )

    def render_show(icon_class, icon_text = nil)
      join_renders(
        (content_tag(:i, '', class: icon_class) if icon_class),
        (capitalize_first_letter(icon_text) if icon_text)
      )
    end
  end
end
