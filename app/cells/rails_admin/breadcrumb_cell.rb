module RailsAdmin
  class BreadcrumbCell < BaseCell
    delegate(
      :content_tag,
      :current_action?,
      :link_to,
      :wording_for,
      to: :view_context
    )
    delegate(
      :url_for,
      to: :rails_admin
    )

    def render_show(global_action, global_object)
      content_tag(:ol, class: 'breadcrumb') do
        join_renders(
          *parent_actions(parent_action(global_action)).map do |a|
            render_parent_action(a, a.bindings[:abstract_model], a.bindings[:object])
          end,
          render_current_action(global_action, abstract_model, global_object)
        )
      end
    end

    private

    def render_parent_action(a, am, o)
      content_tag(:li) do
        text = wording_for(:breadcrumb, a, am, o)

        if a.http_methods.include?(:get)
          id = o.try(:persisted?) && o.try(:id) || nil
          url = url_for(
            action: a.action_name,
            controller: 'rails_admin/main',
            id: id,
            model_name: am.try(:to_param)
          )
          link_to text, url, class: 'pjax'
        else
          content_tag(:span, text)
        end
      end
    end

    def render_current_action(a, am, o)
      content_tag(:li, class: 'active') do
        wording_for(:breadcrumb, a, am, o)
      end
    end

    def parent_actions(action)
      return [] if action.nil?

      parent = parent_action(action)

      return [action] if parent.nil?

      [*parent_actions(parent), action]
    end

    def parent_action(action)
      parent_options = action.breadcrumb_parent

      return if parent_options.nil?

      find_visible_action(*parent_options)
    end

    def find_visible_action(action_name, abstract_model = nil, object = nil)
      super(action_name,
            abstract_model: abstract_model,
            object: object)
    end
  end
end
