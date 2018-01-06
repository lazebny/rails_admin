module RailsAdmin
  class IconCell < BaseCell
    TRANSLATION_SCOPE =  'admin.misc'

    delegate(
      :content_tag,
      :capitalize_first_letter,
      :t,
      to: :view_context
    )

    def render_show(icon_class, icon_text = nil)
      join_renders(
        (content_tag(:i, '', class: icon_class) if icon_class),
        (capitalize_first_letter(icon_text) if icon_text)
      )
    end

    def render_refresh_icon(text: false)
      call(:show, 'icon-white icon-refresh', fetch_text(text, :refresh))
    end

    def render_remove_icon(text: false)
      call(:show, 'icon-white icon-remove', fetch_text(text, :remove))
    end

    private

    def fetch_text(text, icon_name)
      case text
      when FalseClass
      when TrueClass
        t(icon_name, scope: TRANSLATION_SCOPE)
      else
        text
      end
    end
  end
end
