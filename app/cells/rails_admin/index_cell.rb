module RailsAdmin
  class IndexCell < BaseCell
    delegate(
      :authorized?,
      :content_tag,
      :form_tag,
      :link_to,
      :params,
      :t,
      :wording_for,
      to: :view_context
    )
    delegate(
      :description,
      to: :model_config
    )
    delegate(
      :export_path,
      to: :rails_admin
    )

    def render_description
      return unless description.present?

      content_tag(:p) { content_tag(:strong, description) }
    end

    def render_query_form(&block)
      query_params = params.permit(
        :scope,
        :set,
        :sort,
        :sort_reverse,
      ).symbolize_keys

      form_tag(
        current_path(query_params),
        method: :get,
        class: "pjax-form form-inline",
        &block
      )
    end

    def render_export_button
      export_action = find_visible_action(:export, object: nil)
      export_params = params.permit(
        :f,
        :query,
        :scope,
        :sort,
        :sort_revers,
      )

      return if export_action.nil?
      return unless authorized?(export_action.authorization_key, abstract_model)

      content_tag(:span, style: 'float:right') do
        link_to wording_for(:link, export_action),
                export_path(export_params),
                class: 'btn btn-info'
      end
    end
  end
end
