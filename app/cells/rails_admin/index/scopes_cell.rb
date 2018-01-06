module RailsAdmin
  module Index
    class ScopesCell < BaseCell
      SCOPE_ALL = '_all'
      TRANSLATION_SCOPE = 'admin.scopes'

      delegate(
        :content_tag,
        :link_to,
        :params,
        :t,
        to: :view_context
      )

      delegate(
        :index_path,
        to: :rails_admin
      )

      def render_show
        return if scopes.empty?

        content_tag(:ul, id: 'scope_selector', class: 'nav nav-tabs') do
          join_renders(
            *scopes
              .each_with_index
              .map(&method(:render_menu_item))
          )
        end
      end

      private

      def scopes
        model_config.list.scopes
      end

      def scope_active?(scope_name, index)
        scope_name == params[:scope] || (params[:scope].blank? && index.zero?)
      end

      def translate_scope(scope)
        default = t(
          scope,
          default: scope.titleize,
          scope: TRANSLATION_SCOPE
        )
        t(
          [abstract_model.to_param, scope].join('.'),
          default: default,
          scope: TRANSLATION_SCOPE
        )
      end

      def scope_path(scope)
        options = params.permit(
          :f,
          :query,
          :set,
          :sort,
          :sort_reverse
        )
        options[:scope] = scope unless scope == SCOPE_ALL
        index_path(options)
      end

      def render_menu_item(scope, index)
        scope = scope.nil? ? SCOPE_ALL : scope.to_s
        klass = 'active' if scope_active?(scope, index)

        content_tag(:li, class: klass) do
          link_to(translate_scope(scope), scope_path(scope), class: 'pjax')
        end
      end
    end
  end
end
