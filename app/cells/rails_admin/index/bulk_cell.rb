module RailsAdmin
  module Index
    class BulkCell < BaseCell
      delegate(
        :capture,
        :content_tag,
        :form_tag,
        :hidden_field_tag,
        :link_to,
        :t,
        :wording_for,
        to: :view_context
      )
      delegate(
        :bulk_action_path,
        to: :rails_admin
      )

      def render_form(&block)
        path = bulk_action_path(model_name: abstract_model.to_param)
        form_tag(path, method: :post, id: "bulk_form", class: "form") do
          join_renders(
            hidden_field_tag(:bulk_action),
            block.call
          )
        end
      end

      def render_dropdown
        return unless model_config.list.checkboxes?

        bulk_actions = select_visible_actions(object: nil, &:bulkable?)

        return if bulk_actions.empty?

        items = bulk_actions.map do |action|
          onclick = [
            "jQuery('#bulk_action').val('#{action.action_name}')",
            "jQuery('#bulk_form').submit()",
            "return false;"
          ]
          content_tag :li do
            link_to(wording_for(:bulk_link, action), '#', onclick: onclick.join(";\n"))
          end
        end

        view_context.render(
          partial: 'rails_admin/main/shared/dropdown',
          locals: {
            id: nil,
            items: items,
            title: t('admin.misc.bulk_menu_title')
          }
        )
      end
    end
  end
end
