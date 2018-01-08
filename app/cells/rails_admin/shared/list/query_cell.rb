module RailsAdmin
  module Shared
    module List
      class QueryCell < BaseCell
        delegate(
          :button_tag,
          :params,
          :search_field_tag,
          :t,
          to: :view_context
        )

        def initialize(*)
          super
          @icon_cell = ::RailsAdmin::Shared::IconCell.build(view_context)
        end

        def render_search_input
          search_field_tag(
            :query,
            query,
            class: 'form-control input-small',
            placeholder: t("admin.misc.filter")
          )
        end

        def render_submit_button
          refresh_icon = @icon_cell[:refresh_icon, text: true]
          button_tag(
            refresh_icon,
            class: 'btn btn-primary',
            data: {
              'disable-with' => refresh_icon
            }
          )
        end

        private

        def query
          params[:query]
        end
      end
    end
  end
end
